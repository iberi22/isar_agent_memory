# Release Process

This document describes the automated release process for `isar_agent_memory`.

## Overview

The repository uses a fully automated release workflow that:
1. Detects version changes in `pubspec.yaml`
2. Automatically creates Git tags
3. Generates GitHub Releases with CHANGELOG content
4. Optionally publishes to pub.dev

## Release Types

### Stable Releases (e.g., 1.0.0, 0.5.0)
- Automatically published to pub.dev
- Marked as stable releases on GitHub
- Recommended for production use

### Prereleases (e.g., 0.5.0-beta, 1.0.0-rc.1)
- **Not** automatically published to pub.dev
- Marked as prerelease on GitHub
- Can be manually published using workflow_dispatch

## Step-by-Step Release Guide

### 1. Prepare the Release

#### Update Version
Use the automated version update script:

```powershell
# Update to new version across all files
.\tool\update_version.ps1 -NewVersion "0.6.0"

# Example for prerelease:
.\tool\update_version.ps1 -NewVersion "0.6.0-beta"
```

This script updates:
- `pubspec.yaml` - Package version
- `README.md` - Installation example
- Validates version format

#### Update CHANGELOG.md
Add a new section for the release following this format:

```markdown
## [0.6.0] - 2024-01-15

### Added
- New feature description
- Another new feature

### Changed
- Modified behavior description

### Fixed
- Bug fix description

### Breaking Changes
- Breaking change description (if any)
```

**Important**: The workflow extracts release notes from CHANGELOG.md, so ensure the section exists before committing.

### 2. Commit and Push

```powershell
# Review changes
git diff

# Stage all changes
git add pubspec.yaml README.md CHANGELOG.md

# Commit with conventional commit message
git commit -m "chore: bump version to 0.6.0"

# Push to main branch
git push origin main
```

### 3. Automated Workflow Triggers

Once pushed, the `release-on-merge.yml` workflow automatically:

1. **Detects Version Change**
   - Compares current vs previous `pubspec.yaml` version
   - Only triggers if version actually changed
   - Provides detailed logging

2. **Creates Git Tag**
   - Format: `v{version}` (e.g., `v0.6.0`)
   - Skips if tag already exists
   - Pushes tag to GitHub

3. **Extracts Release Notes**
   - Parses CHANGELOG.md for the version section
   - Falls back to link if section not found

4. **Creates GitHub Release**
   - Title: Version tag
   - Body: Content from CHANGELOG.md
   - Prerelease flag set for beta/alpha/rc versions
   - Also generates automatic release notes

5. **Triggers Publish Workflow**
   - For stable releases: Publishes to pub.dev
   - For prereleases: Skips automatic publish

### 4. Verify Release

Check that everything succeeded:

```powershell
# Run verification script
.\tool\verify_release.ps1 -Version "0.6.0"
```

This checks:
- Git tag exists
- GitHub Release created
- pub.dev publication (for stable releases)

### 5. Manual Publish (Optional)

For prereleases or if automatic publish failed:

1. Go to: https://github.com/iberi22/isar_agent_memory/actions/workflows/publish-to-pub-dev.yml
2. Click "Run workflow"
3. Select branch: `main`
4. Choose mode: `publish`
5. Click "Run workflow"

## Workflow Configuration

### Release Workflow (`release-on-merge.yml`)

**Triggers**:
- Push to `main` branch
- Only when `pubspec.yaml` or `CHANGELOG.md` change

**Key Features**:
- Smart version change detection
- CHANGELOG content extraction
- Prerelease detection
- Duplicate tag prevention

### Publish Workflow (`publish-to-pub-dev.yml`)

**Triggers**:
- GitHub Release published (stable only)
- Manual workflow dispatch

**Authentication**:
- Uses `PUB_CREDENTIALS_JSON` secret
- First-time publish requires OAuth
- See `.github/PUB_CREDENTIALS_SETUP.md` for setup

**Modes**:
- `dry-run`: Validates package without publishing
- `publish`: Actually publishes to pub.dev

## Version Consistency

A third workflow (`version-sync.yml`) ensures all version references stay synchronized:

**Checks**:
- `pubspec.yaml` version
- `README.md` dependency version

**Triggers**:
- Pull requests touching version files
- Pushes to main

**Action**: Fails CI if versions don't match

## Troubleshooting

### Workflow Didn't Trigger
- Ensure `pubspec.yaml` or `CHANGELOG.md` was modified
- Check version actually changed
- Verify push reached `main` branch

### Release Has Generic Notes
- CHANGELOG.md section for version missing
- Section header doesn't match version
- Run: `.\tool\update_release.ps1 -Version "0.6.0"`

### Publish Failed
- First-time publish requires OAuth
- Check `PUB_CREDENTIALS_JSON` secret exists
- Verify package passes `dart pub publish --dry-run`

### Version Out of Sync
- Run: `.\tool\update_version.ps1 -NewVersion "0.6.0"`
- This updates all version references

## Best Practices

1. **Always update CHANGELOG.md first** before bumping version
2. **Use semantic versioning**: major.minor.patch[-prerelease]
3. **Test prereleases** before stable releases
4. **Review generated releases** after automation
5. **Keep CHANGELOG detailed** for users
6. **Use conventional commits** for clear history

## Automation Scripts

Located in `tool/`:

- `update_version.ps1` - Update version across all files
- `update_release.ps1` - Manually update GitHub release
- `verify_release.ps1` - Check release completed successfully
- `setup_pub_credentials.ps1` - Configure pub.dev authentication

## References

- [Semantic Versioning](https://semver.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Publishing packages (pub.dev)](https://dart.dev/tools/pub/publishing)
- [GitHub Releases](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases)
