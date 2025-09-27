import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:women_safety_app/components/PrimaryButton.dart';
import 'package:women_safety_app/components/custom_textfield.dart';
import 'package:women_safety_app/utils/constants.dart';

class ReviewPage extends StatefulWidget {
  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final TextEditingController locationC = TextEditingController();
  final TextEditingController viewsC = TextEditingController();
  bool isSaving = false;
  double ratings = 1.0; // default rating
  String? editingDocId; // null = add, not null = update

  @override
  void dispose() {
    locationC.dispose();
    viewsC.dispose();
    super.dispose();
  }

  showAlert(BuildContext context, {DocumentSnapshot? doc}) {
    if (doc != null) {
      // Editing existing review
      locationC.text = doc['location'];
      viewsC.text = doc['views'];
      ratings = (doc['ratings'] is int)
          ? (doc['ratings'] as int).toDouble()
          : (doc['ratings'] ?? 1.0).toDouble();
      editingDocId = doc.id;
    } else {
      // New review
      locationC.clear();
      viewsC.clear();
      ratings = 1.0;
      editingDocId = null;
    }

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(doc == null ? "Review your place" : "Edit Review"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  hintText: 'Enter location',
                  controller: locationC,
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: viewsC,
                  hintText: 'Enter comments',
                  maxLines: 3,
                ),
                const SizedBox(height: 15),
                RatingBar.builder(
                  initialRating: ratings,
                  minRating: 1,
                  direction: Axis.horizontal,
                  itemCount: 5,
                  unratedColor: Colors.grey.shade300,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  itemBuilder: (context, _) =>
                  const Icon(Icons.star, color: kColorDarkRed),
                  onRatingUpdate: (rating) {
                    setState(() {
                      ratings = rating;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            PrimaryButton(
              title: doc == null ? "SAVE" : "UPDATE",
              onPressed: () {
                if (locationC.text.trim().isEmpty ||
                    viewsC.text.trim().isEmpty) {
                  Fluttertoast.showToast(msg: "Please fill all fields");
                  return;
                }
                if (doc == null) {
                  saveReview();
                } else {
                  updateReview(doc.id);
                }
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  Future<void> saveReview() async {
    setState(() {
      isSaving = true;
    });

    await FirebaseFirestore.instance.collection('reviews').add({
      'location': locationC.text.trim(),
      'views': viewsC.text.trim(),
      "ratings": ratings,
      "createdAt": FieldValue.serverTimestamp(),
    }).then((_) {
      setState(() {
        isSaving = false;
      });
      Fluttertoast.showToast(msg: 'Review uploaded successfully');
    }).catchError((e) {
      setState(() => isSaving = false);
      Fluttertoast.showToast(msg: "Error: $e");
    });
  }

  Future<void> updateReview(String docId) async {
    setState(() {
      isSaving = true;
    });

    await FirebaseFirestore.instance.collection('reviews').doc(docId).update({
      'location': locationC.text.trim(),
      'views': viewsC.text.trim(),
      "ratings": ratings,
    }).then((_) {
      setState(() {
        isSaving = false;
      });
      Fluttertoast.showToast(msg: 'Review updated successfully');
    }).catchError((e) {
      setState(() => isSaving = false);
      Fluttertoast.showToast(msg: "Error: $e");
    });
  }

  Future<void> deleteReview(String docId) async {
    await FirebaseFirestore.instance.collection('reviews').doc(docId).delete();
    Fluttertoast.showToast(msg: "Review deleted");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isSaving
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "Recent Reviews by others",
                style:
                TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('reviews')
                    .orderBy("createdAt", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No reviews yet"));
                  }

                  return ListView.separated(
                    separatorBuilder: (context, index) =>
                    const Divider(height: 1),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final data = doc.data() as Map<String, dynamic>;

                      final double rating = (data['ratings'] is int)
                          ? (data['ratings'] as int).toDouble()
                          : (data['ratings'] ?? 0.0).toDouble();

                      return Card(
                        margin: const EdgeInsets.all(6),
                        elevation: 3,
                        child: ListTile(
                          title: Text(
                            "Location: ${data['location'] ?? ''}",
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 5),
                              Text("Comments: ${data['views'] ?? ''}"),
                              const SizedBox(height: 8),
                              RatingBarIndicator(
                                rating: rating,
                                itemBuilder: (context, _) => const Icon(
                                  Icons.star,
                                  color: kColorDarkRed,
                                ),
                                itemCount: 5,
                                itemSize: 22,
                                unratedColor: Colors.grey.shade300,
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == "edit") {
                                showAlert(context, doc: doc);
                              } else if (value == "delete") {
                                deleteReview(doc.id);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                  value: "edit", child: Text("Edit")),
                              const PopupMenuItem(
                                  value: "delete", child: Text("Delete")),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pink,
        onPressed: () => showAlert(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
