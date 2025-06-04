import 'package:googleapis/firestore/v1.dart';
import 'package:read_firestore/read_firestore.dart';

Future<void> main() async {
  // Authenticate using GOOGLE_APPLICATION_CREDENTIALS
  final authClient = await getAuthClient();
  final firestore = FirestoreApi(authClient);

  try {
    // await exportToCsv(documents, 'output.csv');
    // print('Successfully exported ${documents.length} documents to output.csv');
  } finally {
    authClient.close();
  }
}
