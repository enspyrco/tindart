import 'package:args/args.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:read_firestore/read_firestore.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'collection',
      abbr: 'c',
      help: 'Firestore collection name',
      mandatory: true,
    )
    ..addOption(
      'output',
      abbr: 'o',
      help: 'Output CSV file path',
      defaultsTo: 'output.csv',
    )
    ..addOption(
      'project',
      abbr: 'p',
      help: 'Google Cloud project ID',
      mandatory: true,
    );

  final args = parser.parse(arguments);

  // Authenticate using GOOGLE_APPLICATION_CREDENTIALS
  final authClient = await getAuthClient();
  final firestore = FirestoreApi(authClient);

  try {
    final documents = await listDocuments(
      firestore,
      args['project']!,
      args['collection']!,
    );
    await exportToCsv(documents, args['output']!);
    print(
      'Successfully exported ${documents.length} documents to ${args['output']}',
    );
  } finally {
    authClient.close();
  }
}
