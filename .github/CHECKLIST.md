# GitHub Actions Setup Checklist

Use this checklist to ensure your CI/CD is properly configured.

## Initial Setup

### 1. Anthropic API Key

- [ ] Created Anthropic account at <https://console.anthropic.com/>
- [ ] Generated API key from Settings → API Keys
- [ ] Saved API key securely (not in repository!)

### 2. GitHub Secrets

- [ ] Added `ANTHROPIC_API_KEY` secret to repository
  - Path: Settings → Secrets and variables → Actions
  - Secret name is exactly: `ANTHROPIC_API_KEY` (case-sensitive)
- [ ] Verified `GITHUB_TOKEN` is available (auto-provided)

### 3. GitHub Actions Permissions

- [ ] Enabled "Read and write permissions"
  - Path: Settings → Actions → General → Workflow permissions
- [ ] Enabled "Allow GitHub Actions to create and approve pull requests"

### 4. Branch Protection Rules

- [ ] Created branch protection rule for `main`
  - Path: Settings → Branches → Add rule
- [ ] Required status checks:
  - [ ] "Run Tests"
  - [ ] "Claude Code Review"
- [ ] Required pull request reviews
- [ ] Required conversation resolution

## Workflow Files

### Core Files

- [x] `.github/workflows/ci.yml` - Main CI/CD pipeline
- [x] `.github/workflows/README.md` - Documentation
- [x] `.github/SETUP.md` - Setup guide
- [x] `.github/pull_request_template.md` - PR template

## Testing

### First PR Test

- [ ] Created test branch
- [ ] Made a small change
- [ ] Pushed to GitHub
- [ ] Created pull request
- [ ] Verified all checks run:
  - [ ] Run Tests job completed
  - [ ] Claude Code Review job completed
  - [ ] Claude posted review comments (if applicable)
- [ ] Verified build artifacts are created (on main branch)

### Test Results

- [ ] Tests passed ✅
- [ ] Code analysis passed ✅
- [ ] Formatting check passed ✅
- [ ] Claude review completed ✅

## Optional Enhancements

### Documentation

- [ ] Added CI badge to README.md
- [ ] Updated project documentation with CI info
- [ ] Added CONTRIBUTING.md with CI workflow info

### Cost Management

- [ ] Set up billing alerts in Anthropic console
- [ ] Configured PR path filters to limit Claude reviews
- [ ] Considered draft PR exclusion

### Notifications

- [ ] Configured GitHub notification preferences
- [ ] Set up email/Slack notifications for failed builds
- [ ] Configured dependabot for dependency updates

### Advanced Features

- [ ] Added code coverage reporting
- [ ] Configured deployment workflows
- [ ] Set up staging environment
- [ ] Added security scanning (Dependabot, CodeQL)

## Verification

### Workflow Status

Run these commands to verify everything works:

```bash
# Check if workflow file is valid
gh workflow list

# View latest run
gh run list --limit 5

# Check workflow status
gh run view
```

### Expected Results

- [x] Workflow appears in Actions tab
- [x] Runs automatically on push/PR
- [x] All jobs complete successfully
- [x] Claude posts meaningful review comments
- [x] Artifacts are uploaded

## Troubleshooting Completed

If you encountered issues, verify you've addressed them:

- [ ] Fixed "API key not found" error
- [ ] Fixed permission denied errors
- [ ] Resolved test failures in CI
- [ ] Fixed CocoaPods installation issues
- [ ] Addressed any Claude API quota issues

## Maintenance

### Regular Tasks

- [ ] Monitor Anthropic API usage monthly
- [ ] Review and update Flutter version in workflow
- [ ] Keep dependencies updated
- [ ] Review and improve test coverage
- [ ] Audit workflow performance and costs

### Monthly Review

- [ ] Check Anthropic API costs
- [ ] Review failed builds/patterns
- [ ] Update workflow if needed
- [ ] Clean up old artifacts

## Resources Reviewed

- [ ] Read [workflows/README.md](.github/workflows/README.md)
- [ ] Read [SETUP.md](.github/SETUP.md)
- [ ] Reviewed [Claude Code Action docs](https://github.com/anthropics/claude-code-action)
- [ ] Reviewed [GitHub Actions docs](https://docs.github.com/en/actions)

## Ready to Use! 🎉

Once all items are checked:

- ✅ Your CI/CD is fully configured
- ✅ Claude Code reviews are active
- ✅ Tests run automatically
- ✅ Builds are generated on every merge to main

---

**Next Steps:**

1. Start using PRs for all changes
1. Let Claude review your code
1. Keep tests updated
1. Monitor and optimize costs

**Need Help?**

- Check [SETUP.md](.github/SETUP.md) for detailed instructions
- Check [workflows/README.md](.github/workflows/README.md) for troubleshooting
- Open an issue if problems persist
