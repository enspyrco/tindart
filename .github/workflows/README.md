# CI/CD Workflows

Automated testing, code review, and builds for TindArt.

## Overview

**Workflow:** `ci.yml`

**Triggers:** Push to `main`/`develop` or any pull request

### Jobs

| Job                    | Runs On       | Trigger          | Purpose                     |
| ---------------------- | ------------- | ---------------- | --------------------------- |
| **test**               | ubuntu-latest | All pushes & PRs | Format, lint, analyze, test |
| **claude-code-review** | ubuntu-latest | PRs only         | AI-powered code review      |
| **build-android**      | ubuntu-latest | Push to `main`   | Build release APK           |
| **build-ios**          | macos-latest  | Push to `main`   | Build iOS app               |

### What Gets Checked

**Automated Tests:**

- ✅ Code formatting (`dart format`)
- ✅ Static analysis (`flutter analyze`)
- ✅ Unit & widget tests (`flutter test`)

**Claude Code Review (PRs only):**

- 🤖 Bug detection (especially index-based operations)
- 🔒 Security vulnerabilities
- ⚡ Performance issues
- 🎯 Firestore operation validation
- 🔑 Auth flow correctness

## Quick Setup

See [../SETUP.md](../SETUP.md) for detailed instructions.

### Required Secret

Add `ANTHROPIC_API_KEY` to repository secrets:

1. Get key: <https://console.anthropic.com/>
1. Add at: Settings → Secrets and variables → Actions → New repository secret

### Enable Permissions

Settings → Actions → General:

- Select "Read and write permissions"
- Check "Allow GitHub Actions to create and approve pull requests"

## Usage

### Viewing Results

- **All runs:** Actions tab
- **PR reviews:** Claude comments directly on pull requests
- **Artifacts:** Actions → CI → Latest run → Artifacts section

### Downloading Builds

From successful `main` branch runs:

- `app-release-apk` - Android APK
- `ios-build` - iOS app (no codesigning)
- `test-results` - Test outputs

## Cost Management

Claude reviews: ~$0.10-$0.50 per PR

### Reduce Costs

```yaml
# Skip draft PRs
if: github.event.pull_request.draft == false

# Only review Dart files
paths:
  - "lib/**/*.dart"
  - "test/**/*.dart"

# Reduce token usage
max_tokens: 2000
```

## Troubleshooting

### Tests Fail

**Flutter version mismatch:**

- Update `flutter-version` in `ci.yml` to match local: `flutter --version`

**Dependency issues:**

- Verify `pubspec.yaml` is valid
- Run `flutter pub get` locally first

### Claude Review Fails

**API key not found:**

- Verify `ANTHROPIC_API_KEY` secret exists (case-sensitive)

**Quota exceeded:**

- Check usage: <https://console.anthropic.com/settings/usage>
- Add billing or limit reviews (see Cost Management)

### iOS Build Fails

**CocoaPods:**

- Verify `Podfile` is valid
- Ensure all pods are available

**Xcode version:**

```yaml
- name: Select Xcode
  run: sudo xcode-select -s /Applications/Xcode_15.0.app
```

## Advanced

### Code Coverage

```yaml
- name: Run tests with coverage
  run: flutter test --coverage

- name: Upload to Codecov
  uses: codecov/codecov-action@v4
  with:
    file: coverage/lcov.info
```

### Custom Flutter Version

```yaml
- name: Setup Flutter
  uses: subosito/flutter-action@v2
  with:
    flutter-version: "3.24.0"
    channel: "stable"
```

### Parallel Testing

```yaml
- name: Run tests
  run: flutter test --concurrency=4
```

## Resources

- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Flutter CI/CD Guide](https://docs.flutter.dev/deployment/cd)
- [Claude Code Action](https://github.com/anthropics/claude-code-action)
- [Anthropic API Docs](https://docs.anthropic.com/)
