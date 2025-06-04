import 'dart:io';
import 'package:googleapis/firestore/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:csv/csv.dart';
import 'package:http/http.dart' as http;

const parent = 'projects/tindart-8c83b/databases/(default)/documents';

Future<http.Client> getAuthClient() async {
  // This will automatically use GOOGLE_APPLICATION_CREDENTIALS environment variable
  final client = await clientViaApplicationDefaultCredentials(
    scopes: ['https://www.googleapis.com/auth/datastore'],
  );
  return client;
}

Future<Document> retrieveDocument(
  FirestoreApi firestore,
  String collectionPath,
  String id,
) async {
  final response = await firestore.projects.databases.documents.get(
    '$parent/$collectionPath/$id',
  );

  return response;
}

Future<List<Document>> retrieveDocuments(
  FirestoreApi firestore,
  String collection,
) async {
  final response = await firestore.projects.databases.documents.list(
    parent,
    collection,
  );

  return response.documents ?? [];
}

Future<Document> createDocument(
  FirestoreApi firestore,
  Document document,
  String collectionId,
) async {
  final response = await firestore.projects.databases.documents.createDocument(
    document,
    parent,
    collectionId,
  );

  return response;
}

Future<void> exportToCsv(List<Document> documents, String outputPath) async {
  if (documents.isEmpty) {
    print('No documents found in collection');
    return;
  }

  final List<List<Object?>> csvData = [];

  // Get field names from first document
  final fields = documents.first.fields?.keys.toList() ?? [];
  csvData.add(fields); // Header row

  // Add data rows
  for (final doc in documents) {
    final row = fields.map((field) {
      final value = doc.fields?[field];
      return value?.stringValue ?? '';
    }).toList();
    csvData.add(row);
  }

  final csv = const ListToCsvConverter().convert(csvData);
  await File(outputPath).writeAsString(csv);
}
