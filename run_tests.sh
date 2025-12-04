#!/bin/bash

# Test runner script for TindArt

echo "================================="
echo "TindArt Test Suite"
echo "================================="
echo ""

# Check if flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    echo "Please install Flutter: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "📦 Installing dependencies..."
flutter pub get

if [ $? -ne 0 ]; then
    echo "❌ Failed to install dependencies"
    exit 1
fi

echo ""
echo "🧪 Running tests..."
echo ""

flutter test --reporter expanded

if [ $? -eq 0 ]; then
    echo ""
    echo "================================="
    echo "✅ All tests passed!"
    echo "================================="
    echo ""
    echo "The like/dislike bug fix has been verified."
    echo ""
    echo "Next steps:"
    echo "1. Run the app and manually test swiping through 3+ batches"
    echo "2. Check Firestore to verify correct IDs are saved"
    echo "3. See test/README.md for detailed manual test plan"
else
    echo ""
    echo "================================="
    echo "❌ Some tests failed"
    echo "================================="
    echo ""
    echo "Please review the errors above and fix any issues."
    exit 1
fi
