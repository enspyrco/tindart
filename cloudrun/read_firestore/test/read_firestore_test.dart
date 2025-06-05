import 'package:googleapis/firestore/v1.dart';
import 'package:read_firestore/read_firestore.dart';
import 'package:test/test.dart';

void main() {
  test('Preference matrix generation', () async {
    // 1. Mock Firestore data
    final mockIdListDoc = Document(
      fields: {
        'ids': Value(
          arrayValue: ArrayValue(
            values: [
              Value(stringValue: 'item1'),
              Value(stringValue: 'item2'),
            ],
          ),
        ),
      },
    );

    final mockPreferences = {
      'user1': Document(
        fields: {
          'liked': Value(
            arrayValue: ArrayValue(values: [Value(stringValue: 'item1')]),
          ),
          'disliked': Value(arrayValue: ArrayValue()),
        },
      ),
      'user2': Document(
        fields: {
          'liked': Value(arrayValue: ArrayValue()),
          'disliked': Value(
            arrayValue: ArrayValue(values: [Value(stringValue: 'item2')]),
          ),
        },
      ),
    };

    // 2. Run the test
    final matrix = await createPreferenceMatrix(mockPreferences, mockIdListDoc);

    // 3. Verify the output
    expect(matrix, [
      ['', 'user1', 'user2'],
      ['item1', '1', '0'],
      ['item2', '0', '-1'],
    ]);

    // 4. Print the matrix for visualization
    print('\nGenerated Preference Matrix:');
    for (final row in matrix) {
      print(row.map((cell) => cell.padLeft(5)).join(' | '));
    }
  });
}
