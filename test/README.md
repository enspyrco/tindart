# Test Documentation

## Running the Tests

### Install Dependencies
```bash
flutter pub get
```

### Run All Tests
```bash
flutter test
```

### Run Specific Test
```bash
flutter test test/home_screen_test.dart
```

### Run with Verbose Output
```bash
flutter test --reporter expanded
```

## Test Coverage

### `home_screen_test.dart`
Tests the fix for the like/dislike saving bug in HomeScreen.

**What it tests:**
1. **Index Mapping Logic** - Verifies that the correct document IDs are saved when swiping through multiple batches
2. **Bounds Checking** - Ensures the app doesn't crash with out-of-bounds errors

**Bug that was fixed:**
Before the fix, when users swiped through multiple batches of cards, the app would save the wrong image IDs. For example:
- Batch 1: Swipe card #2 → saves `img3` ✓ correct
- Batch 2: Swipe card #2 → saves `img3` (from batch 1!) ✗ wrong, should be `img8`

**The fix:**
- Now uses `_cardDocIds` list to track current batch's document IDs
- Always saves the correct ID regardless of which batch you're viewing

## Manual Testing

See the test file for a complete manual test plan. Quick steps:

1. **Setup:** Use a test account or clear existing preferences
2. **Test:** Swipe through at least 15 cards (3 batches)
3. **Verify:** Check Firestore to ensure saved IDs match the actual cards you swiped

### Quick Firestore Check
```bash
# In Firebase Console, check:
# - Collection: preferences/{userId}
# - Fields: liked[], disliked[]
#
# Verify:
# - IDs match the actual images you liked/disliked
# - No duplicate IDs for different cards
# - Each batch saves unique IDs
```

## Adding More Tests

To add integration tests that test the full Firebase flow, you'll need to:

1. Make `HomeScreen` accept Firestore/Auth instances via constructor (dependency injection)
2. Use `fake_cloud_firestore` and `firebase_auth_mocks` in tests
3. Set up test data in the fake Firestore instance

Example structure:
```dart
test('Full swipe flow with mocked Firebase', () async {
  // Setup fake Firestore
  final firestore = FakeFirebaseFirestore();
  final auth = MockFirebaseAuth();

  // Add test data
  await firestore.collection('doc-id-lists')
    .doc('test-list')
    .set({'ids': ['img1', 'img2', ...]});

  // Create widget with injected dependencies
  await tester.pumpWidget(
    MaterialApp(
      home: HomeScreen(
        firestore: firestore,
        auth: auth,
      ),
    ),
  );

  // Simulate swipe
  // Verify Firestore was updated correctly
});
```

## Test Results Interpretation

✅ **All tests passing** = The bug fix is working correctly
❌ **Tests failing** = There may be a regression in the fix

The logic tests verify the core algorithm works correctly. Manual testing verifies the Firebase integration works in the real app.
