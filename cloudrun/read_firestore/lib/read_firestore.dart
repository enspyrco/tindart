import 'package:googleapis/firestore/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
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

Future<List<List<String>>> createPreferenceMatrix(
  Map<String, Document> preferences,
  Document idListDoc,
) async {
  // 1. Extract row and column headings
  final rowHeadings =
      idListDoc.fields?['ids']?.arrayValue?.values
          ?.map((v) => v.stringValue ?? '')
          .where((id) => id.isNotEmpty)
          .toList() ??
      [];

  final columnHeadings = preferences.keys.toList();

  // 2. Initialize the matrix with all zeros
  final matrix = List.generate(
    rowHeadings.length,
    (_) => List.filled(columnHeadings.length, '0'),
  );

  // 3. Populate the matrix with 1s and -1s
  for (var col = 0; col < columnHeadings.length; col++) {
    final prefDoc = preferences[columnHeadings[col]]!;

    final liked =
        prefDoc.fields?['liked']?.arrayValue?.values
            ?.map((v) => v.stringValue ?? '')
            .where((id) => id.isNotEmpty)
            .toList() ??
        [];

    final disliked =
        prefDoc.fields?['disliked']?.arrayValue?.values
            ?.map((v) => v.stringValue ?? '')
            .where((id) => id.isNotEmpty)
            .toList() ??
        [];

    for (var row = 0; row < rowHeadings.length; row++) {
      if (liked.contains(rowHeadings[row])) {
        matrix[row][col] = '1';
      } else if (disliked.contains(rowHeadings[row])) {
        matrix[row][col] = '-1';
      }
    }
  }

  // 4. Add headers to the matrix
  final matrixWithHeaders = [
    [''] + columnHeadings, // First row: empty + column headings
    ...matrix.asMap().entries.map(
      (entry) => [rowHeadings[entry.key]] + entry.value,
    ),
  ];

  return matrixWithHeaders;
}

Future<Map<String, Document>> getDocumentsMap(
  FirestoreApi firestore,
  String collectionId,
) async {
  final documents = <String, Document>{};
  String? nextPageToken;

  do {
    final response = await firestore.projects.databases.documents.list(
      parent,
      collectionId,
      pageSize: 300,
      pageToken: nextPageToken,
    );

    for (final doc in response.documents ?? []) {
      final docId = doc.name.split('/').last;
      documents[docId] = doc;
    }

    nextPageToken = response.nextPageToken;
  } while (nextPageToken != null);

  return documents;
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
