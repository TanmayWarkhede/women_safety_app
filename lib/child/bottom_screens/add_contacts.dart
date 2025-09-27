import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sqflite/sqflite.dart';
import 'package:women_safety_app/child/bottom_screens/contacts_page.dart';
import 'package:women_safety_app/components/PrimaryButton.dart';
import 'package:women_safety_app/db/db_services.dart';
import 'package:women_safety_app/model/contactsm.dart';

class AddContactsPage extends StatefulWidget {
  const AddContactsPage({super.key});

  @override
  State<AddContactsPage> createState() => _AddContactsPageState();
}

class _AddContactsPageState extends State<AddContactsPage> {
  final DatabaseHelper databaseHelper = DatabaseHelper();
  List<TContact> contactList = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showList();
    });
  }

  Future<void> showList() async {
    final Database db = await databaseHelper.initializeDatabase();
    final List<TContact> contacts = await databaseHelper.getContactList();
    setState(() {
      contactList = contacts;
    });
  }

  Future<void> deleteContact(TContact contact) async {
    final int result = await databaseHelper.deleteContact(contact.id);
    if (result != 0) {
      Fluttertoast.showToast(msg: "Contact removed successfully");
      showList();
    }
  }

  Future<void> callContact(String number) async {
    try {
      await FlutterPhoneDirectCaller.callNumber(number);
    } catch (e) {
      Fluttertoast.showToast(msg: "Could not place call: $e");
    }
  }

  void confirmDelete(TContact contact) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Contact"),
        content: Text("Are you sure you want to delete ${contact.name}?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              deleteContact(contact);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            PrimaryButton(
              title: "Add Trusted Contacts",
              onPressed: () async {
                final bool? result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ContactsPage(),
                  ),
                );
                if (result == true) {
                  showList();
                }
              },
            ),
            Expanded(
              child: contactList.isEmpty
                  ? const Center(
                child: Text(
                  "No contacts added yet",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: contactList.length,
                itemBuilder: (context, index) {
                  final contact = contactList[index];
                  return Card(
                    child: ListTile(
                      title: Text(contact.name),
                      subtitle: Text(contact.number),
                      trailing: SizedBox(
                        width: 100,
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () => callContact(contact.number),
                              icon: const Icon(Icons.call,
                                  color: Colors.green),
                            ),
                            IconButton(
                              onPressed: () => confirmDelete(contact),
                              icon: const Icon(Icons.delete,
                                  color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
