import 'dart:io';

import 'package:csv/csv.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:read_firestore/read_firestore.dart';

const pageSize = 300; // Firestore's max page size

Future<void> main() async {
  // Authenticate using GOOGLE_APPLICATION_CREDENTIALS
  final authClient = await getAuthClient();
  final firestore = FirestoreApi(authClient);

  try {
    // 1. Get all documents from 'preferences' collection
    final Map<String, Document> preferences = await getDocumentsMap(
      firestore,
      'preferences',
    );

    // 2. Get the specific document from 'doc-id-lists'
    final Document idListDoc = await retrieveDocument(
      firestore,
      'doc-id-lists',
      'RMCevRY4dGpUTTcrltun',
    );

    // 3.
    final List<List<String>> matrixWithHeaders = await createPreferenceMatrix(
      preferences,
      idListDoc,
    );

    // 4.
    final csv = const ListToCsvConverter().convert(matrixWithHeaders);
    await File('output.csv').writeAsString(csv);

    print(
      'Successfully exported ${matrixWithHeaders.length}x${matrixWithHeaders.first.length} matrix to output.csv',
    );
  } catch (e) {
    print('Error fetching documents: $e');
    rethrow;
  } finally {
    authClient.close();
  }
}
