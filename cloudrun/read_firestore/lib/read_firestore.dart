import 'dart:io';
import 'package:googleapis/firestore/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:csv/csv.dart';
import 'package:http/http.dart' as http;

Future<http.Client> getAuthClient() async {
  // This will automatically use GOOGLE_APPLICATION_CREDENTIALS environment variable
  final client = await clientViaApplicationDefaultCredentials(
    scopes: ['https://www.googleapis.com/auth/datastore'],
  );
  return client;
}

Future<List<Document>> listDocuments(
  FirestoreApi firestore,
  String projectId,
  String collection,
) async {
  final parent = 'projects/$projectId/databases/(default)/documents';
  final response = await firestore.projects.databases.documents.list(
    parent,
    collection,
  );

  return response.documents ?? [];
}

Future<void> exportToCsv(List<Document> documents, String outputPath) async {
  if (documents.isEmpty) {
    print('No documents found in collection');
    return;
  }

  final List<List<dynamic>> csvData = [];

  // Get field names from first document
  final fields = documents.first.fields?.keys.toList() ?? [];
  csvData.add(fields); // Header row

  // Add data rows
  for (final doc in documents) {
    final row = fields.map((field) {
      final value = doc.fields?[field];
      return value?.toString() ?? '';
    }).toList();
    csvData.add(row);
  }

  final csv = const ListToCsvConverter().convert(csvData);
  await File(outputPath).writeAsString(csv);
}
