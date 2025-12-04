# GitHub Actions Setup Guide

Quick guide to get CI/CD running for TindArt.

## 1. Get Anthropic API Key

1. Go to <https://console.anthropic.com/>
1. Sign up or log in
1. Navigate to **Settings → API Keys**
1. Click **Create Key**
1. Copy the key (starts with `sk-ant-`)

**Important:** Keep this key secure and never commit it to your repository!

## 2. Add Secret to GitHub

1. Go to your GitHub repository
1. Click **Settings** (requires admin access)
1. Click **Secrets and variables** → **Actions**
1. Click **New repository secret**
1. Add secret:
   - Name: `ANTHROPIC_API_KEY`
   - Value: Paste your API key from step 1
1. Click **Add secret**

## 3. Enable GitHub Actions

1. Go to **Settings → Actions → General**
1. Under **Workflow permissions**:
   - Select "Read and write permissions"
   - Check "Allow GitHub Actions to create and approve pull requests"
1. Click **Save**

## 4. Test the Workflow

### Option A: Create a Test PR

```bash
# Create a new branch
git checkout -b test/github-actions

# Make a small change (e.g., add a comment)
echo "// Test comment" >> lib/main.dart

# Commit and push
git add .
git commit -m "Test: Verify GitHub Actions workflow"
git push -u origin test/github-actions

# Create PR on GitHub
# You should see the workflow running automatically
```

### Option B: Push to Main

```bash
# Make sure you're on main
git checkout main

# Push the workflow files
git add .github/
git commit -m "Add GitHub Actions CI/CD workflow"
git push

# Check the Actions tab to see it running
```

## 5. Verify Workflow is Running

1. Go to **Actions** tab in your repository
1. You should see a workflow run for your recent push/PR
1. Click on it to see the progress
1. All jobs should complete successfully ✅

## 6. Optional: Add Status Badge to README

Add this to your `README.md`:

```markdown
![CI](https://github.com/YOUR_USERNAME/tindart/workflows/CI/badge.svg)
```

Replace `YOUR_USERNAME` with your GitHub username.

## 7. Configure Branch Protection (Recommended)

Protect your `main` branch to require passing CI before merging:

1. Go to **Settings → Branches**
1. Click **Add rule** (or edit existing `main` rule)
1. Branch name pattern: `main`
1. Check these options:
   - ✅ Require status checks to pass before merging
     - Search and select: "Run Tests"
     - Search and select: "Claude Code Review"
   - ✅ Require pull request reviews before merging
   - ✅ Require conversation resolution before merging
1. Click **Create** or **Save changes**

Now all PRs to `main` must pass tests and Claude review!

## Troubleshooting

### "Anthropic API key not found"

- Double-check the secret name is exactly `ANTHROPIC_API_KEY`
- Verify you have access to repository settings
- Try deleting and re-adding the secret

### "Permission denied" errors

- Ensure workflow permissions are set to "Read and write"
- Check "Allow GitHub Actions to create and approve pull requests" is enabled

### Claude Code Action doesn't run

- It only runs on pull requests, not direct pushes
- Check that the PR is targeting `main` or `develop` branch
- Ensure it's not a draft PR (or remove the draft check from workflow)

### Tests fail in CI but pass locally

- Check Flutter version matches between local and CI
- Ensure all dependencies are in `pubspec.yaml`
- Verify test data/fixtures are committed
- Check for hardcoded paths that differ between environments

## Cost Management

### Monitor Anthropic API Usage

1. Go to <https://console.anthropic.com/settings/usage>
1. View your API usage and costs
1. Set up billing alerts if needed

### Typical Costs

- Claude Code review per PR: ~$0.10 - $0.50 depending on PR size
- Free tier: $5/month credit (50-100 PR reviews)
- Paid plans: Check <https://www.anthropic.com/pricing>

### Reduce Costs

Edit `.github/workflows/ci.yml` to:

1. **Skip draft PRs:**

```yaml
if: github.event_name == 'pull_request' && github.event.pull_request.draft == false
```

2. **Only review specific files:**

```yaml
on:
  pull_request:
    paths:
      - "lib/**/*.dart"
      - "test/**/*.dart"
```

3. **Limit review scope:**

```yaml
with:
  max_tokens: 2000 # Reduce from default
```

## Next Steps

After setup is complete:

1. ✅ Create a test PR to verify everything works
1. ✅ Review Claude's code review comments
1. ✅ Set up branch protection rules
1. ✅ Add CI badge to README
1. ✅ Configure notifications for failed builds

## Support

- GitHub Actions: <https://docs.github.com/en/actions>
- Claude Code Action: <https://github.com/anthropics/claude-code-action>
- Flutter CI/CD: <https://docs.flutter.dev/deployment/cd>
- Issues: Create an issue in this repository

---

**Quick Command Reference:**

```bash
# View workflow status
gh run list

# View latest run
gh run view

# Re-run failed jobs
gh run rerun <run-id>

# Download artifacts
gh run download <run-id>
```
