---
applyTo: ".github/workflows/**/*.yml,.github/workflows/**/*.yaml"
---

# GitHub Actions Workflow Instructions

When working with CI/CD workflows in this repository:

## Existing Workflows

| Workflow | Purpose | Trigger |
|----------|---------|---------|
| `ci.yml` | Lint, analyze, test | PR, Push |
| `release-on-merge.yml` | Create tags/releases | Push to main |
| `publish-to-pub-dev.yml` | Publish to pub.dev | Release published |
| `version-sync.yml` | Validate versions | PR, Push |

## Dart Setup

Always use Dart SDK setup:
```yaml
- name: Setup Dart SDK
  uses: dart-lang/setup-dart@v1
  with:
    sdk: stable
```

## Standard Steps

```yaml
- name: Install dependencies
  run: dart pub get

- name: Verify formatting
  run: dart format --output=none --set-exit-if-changed .

- name: Analyze code
  run: dart analyze

- name: Run tests
  run: dart test
```

## Version Detection

Extract version from pubspec.yaml:
```yaml
- name: Get version
  run: |
    VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}')
    echo "version=$VERSION" >> $GITHUB_OUTPUT
```

## Prerelease Detection

```yaml
- name: Check prerelease
  run: |
    if echo "$VERSION" | grep -qE '(alpha|beta|rc|dev|pre)'; then
      echo "is_prerelease=true" >> $GITHUB_OUTPUT
    else
      echo "is_prerelease=false" >> $GITHUB_OUTPUT
    fi
```

## Secrets Used

- `GITHUB_TOKEN` - Auto-provided for releases
- `PUB_CREDENTIALS_JSON` - pub.dev authentication

## Best Practices

- Use `set -euo pipefail` in bash scripts
- Always checkout with `fetch-depth: 0` for tag operations
- Use step outputs to share data between steps
- Add meaningful step names
- Include logging with emoji indicators

## Do NOT

- ❌ Remove existing workflow triggers without understanding impact
- ❌ Skip `dart analyze` step
- ❌ Hard-code secrets in workflow files
