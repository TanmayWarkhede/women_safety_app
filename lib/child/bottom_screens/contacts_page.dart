import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:women_safety_app/db/db_services.dart';
import 'package:women_safety_app/model/contactsm.dart';
import 'package:women_safety_app/utils/constants.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({Key? key}) : super(key: key);

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final TextEditingController searchController = TextEditingController();

  List<Contact> contacts = [];
  List<Contact> contactsFiltered = [];

  @override
  void initState() {
    super.initState();
    askPermissions();
  }

  String flattenPhoneNumber(String phoneStr) {
    return phoneStr.replaceAllMapped(RegExp(r'^(\+)|\D'), (Match m) {
      return m[0] == "+" ? "+" : "";
    });
  }

  void filterContacts() {
    List<Contact> _contacts = List.from(contacts);
    if (searchController.text.isNotEmpty) {
      _contacts.retainWhere((element) {
        final searchTerm = searchController.text.toLowerCase();
        final searchTermFlatten = flattenPhoneNumber(searchTerm);
        final contactName = (element.displayName ?? "").toLowerCase();

        if (contactName.contains(searchTerm)) return true;

        if (searchTermFlatten.isEmpty || element.phones == null) {
          return false;
        }

        return element.phones!.any((p) {
          final phoneFlatten = flattenPhoneNumber(p.value ?? "");
          return phoneFlatten.contains(searchTermFlatten);
        });
      });
    }
    setState(() {
      contactsFiltered = _contacts;
    });
  }

  Future<void> askPermissions() async {
    final status = await getContactsPermissions();
    if (status == PermissionStatus.granted) {
      getAllContacts();
      searchController.addListener(filterContacts);
    } else {
      handleInvalidPermissions(status);
    }
  }

  void handleInvalidPermissions(PermissionStatus status) {
    if (status == PermissionStatus.denied) {
      dialogueBox(context, "Access to contacts denied by the user");
    } else if (status == PermissionStatus.permanentlyDenied) {
      dialogueBox(context, "Permission permanently denied. Enable from settings.");
    }
  }

  Future<PermissionStatus> getContactsPermissions() async {
    final permission = await Permission.contacts.status;
    if (permission != PermissionStatus.granted &&
        permission != PermissionStatus.permanentlyDenied) {
      return await Permission.contacts.request();
    } else {
      return permission;
    }
  }

  Future<void> getAllContacts() async {
    try {
      final _contacts = await ContactsService.getContacts(withThumbnails: false);
      setState(() {
        contacts = _contacts;
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to load contacts: $e");
    }
  }

  void _addContact(TContact newContact) async {
    final result = await _databaseHelper.insertContact(newContact);
    if (result != 0) {
      Fluttertoast.showToast(msg: "Contact added successfully");
      Navigator.of(context).pop(true);
    } else {
      Fluttertoast.showToast(msg: "Failed to add contact (maybe duplicate?)");
    }
  }

  void confirmAddContact(Contact contact) {
    final phone = contact.phones?.isNotEmpty == true
        ? contact.phones!.first.value ?? ""
        : "";

    if (phone.isEmpty) {
      Fluttertoast.showToast(msg: "This contact has no phone number");
      return;
    }

    final name = contact.displayName ?? "Unknown";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add Contact"),
        content: Text("Do you want to add $name to trusted contacts?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _addContact(TContact(phone, name));
            },
            child: const Text("Add", style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = searchController.text.isNotEmpty;
    final hasItems = contactsFiltered.isNotEmpty || contacts.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Contact"),
        backgroundColor: kColorRed,
      ),
      body: contacts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  labelText: "Search Contact",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            hasItems
                ? Expanded(
              child: ListView.builder(
                itemCount: isSearching
                    ? contactsFiltered.length
                    : contacts.length,
                itemBuilder: (context, index) {
                  final contact = isSearching
                      ? contactsFiltered[index]
                      : contacts[index];
                  return ListTile(
                    title: Text(contact.displayName ?? ""),
                    subtitle: contact.phones?.isNotEmpty == true
                        ? Text(contact.phones!.first.value ?? "")
                        : const Text("No number"),
                    leading: contact.avatar != null &&
                        contact.avatar!.isNotEmpty
                        ? CircleAvatar(
                      backgroundImage:
                      MemoryImage(contact.avatar!),
                    )
                        : CircleAvatar(
                      backgroundColor: kColorRed,
                      child: Text(contact.initials()),
                    ),
                    onTap: () => confirmAddContact(contact),
                  );
                },
              ),
            )
                : const Center(child: Text("No contacts found")),
          ],
        ),
      ),
    );
  }
}
