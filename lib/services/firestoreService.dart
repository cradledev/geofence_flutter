import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

final CollectionReference _todolistCollectionRef =
    FirebaseFirestore.instance.collection('ToDoList');

class FireStoreService {
  static String? userUid;

  // create
  static Future<void> addItem(
      {required String title,
      required String description,
      required String type,
      required String mapData}) async {
    DocumentReference documentReferencer =
        _todolistCollectionRef.doc(userUid).collection('GeoFences').doc();

    Map<String, dynamic> data = <String, dynamic>{
      "title": title,
      "description": description,
      "type": type,
      "data": mapData
    };

    await documentReferencer
        .set(data)
        .whenComplete(() => print("Notes item added to the database"))
        .catchError((e) => print(e));
  }

  // read
  static Stream<QuerySnapshot> readItems() {
    CollectionReference _geoFencesCollectionRef =
        _todolistCollectionRef.doc(userUid).collection('GeoFences');

    return _geoFencesCollectionRef.snapshots();
  }

  // read function using Future
  static Future<QuerySnapshot> readItemsByFuture() async {
    CollectionReference _geoFencesCollectionRef =
        _todolistCollectionRef.doc(userUid).collection('GeoFences');
    return await _geoFencesCollectionRef.get();
  }

  // update
  static Future<void> updateItem({
    required String title,
    required String description,
    required String type,
    required String mapData,
    required String docId,
  }) async {
    DocumentReference documentReferencer =
        _todolistCollectionRef.doc(userUid).collection('GeoFences').doc(docId);

    Map<String, dynamic> data = <String, dynamic>{
      "title": title,
      "description": description,
      "type": type,
      "data": mapData
    };

    await documentReferencer
        .update(data)
        .whenComplete(() => print("Note item updated in the database"))
        .catchError((e) => print(e));
  }

  // delete
  static Future<void> deleteItem({
    required String docId,
  }) async {
    DocumentReference documentReferencer =
        _todolistCollectionRef.doc(userUid).collection('GeoFences').doc(docId);

    await documentReferencer
        .delete()
        .whenComplete(() => print('Note item deleted from the database'))
        .catchError((e) => print(e));
  }
}
