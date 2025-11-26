---
applyTo: "pubspec.yaml,CHANGELOG.md,README.md"
---

# Release File Instructions

When modifying version-related files:

## CRITICAL: Version Updates

**NEVER manually edit version in multiple files.**

Use the version script:
```powershell
.\tool\update_version.ps1 -NewVersion "X.Y.Z"
```

This ensures version consistency across:
- `pubspec.yaml` version field
- `README.md` installation example

## CHANGELOG.md Format

Add new entries at the TOP of the file:

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- New feature description

### Changed
- Modified behavior

### Fixed
- Bug fix description

### Breaking Changes
- Breaking change (if any)
```

## Version Formats

| Type | Format | Example |
|------|--------|---------|
| Stable | `X.Y.Z` | `1.0.0` |
| Beta | `X.Y.Z-beta` | `1.0.0-beta` |
| Alpha | `X.Y.Z-alpha` | `1.0.0-alpha` |
| RC | `X.Y.Z-rc.N` | `1.0.0-rc.1` |

## Commit Message

Use conventional commits:
```bash
git commit -m "chore: bump version to X.Y.Z"
```

## What Happens After Push

1. `version-sync.yml` validates consistency
2. `release-on-merge.yml` creates tag and GitHub Release
3. `publish-to-pub-dev.yml` publishes stable versions

## Do NOT

- ❌ Skip CHANGELOG.md updates
- ❌ Edit version manually in multiple files
- ❌ Use non-conventional commit messages for releases
