# CLAUDE.md

> Configuration file for Claude Code (claude.ai/code) - AI coding assistant.
> This file provides project-specific context and instructions for Claude Code sessions.

## Project Overview

**Name:** isar_agent_memory
**Type:** script
**Stack:** Unknown
**Description:** 🧠 isar_agent_memory
**Location:** E:\scripts-python\isar_agent_memory

---

## 🚀 Getting Started

### Prerequisites
```bash
# Verify required tools are installed
# No special prerequisites
```

### Installation & Setup
```bash
# Install dependencies
# Check package.json or setup.py
```

### Development
```bash
# Start development server
# See README.md
```

### Build & Test
```bash
# Build for production
# See package.json or Makefile

# Run tests
# See package.json

# Lint and format
# See package.json or .eslintrc
```

---

## 📁 Project Structure

```
AGENTS.md
analysis_options.yaml
analyze_final.txt
analyze_output.txt
AUTOMATION_SUMMARY.md
CHANGELOG.md
CODE_OF_CONDUCT.md
CONTRIBUTING.md
doc/
example/
isar_agent_memory_tests/
lib/
LICENSE
pubspec.lock
pubspec.yaml
```

### Key Directories

| Directory | Purpose |
|-----------|---------|
| lib/ | Main source code |
| config/ | Configuration files |
| tests/ | Test files |
| docs/ | Documentation |

---

## 🏗️ Architecture

Simple project structure

### Technology Stack

| Component | Technology | Version/Notes |
|-----------|-------------|---------------|
| Core | N/A |  |
| Config | N/A |  |

### Key Patterns
- **Standard**: Basic project structure
- **N/A**: 

---

## 🔧 Development Workflow

### Git Workflow (GitCore Protocol)
```bash
# Create issue branch
git checkout -b feat/description-##issue

# Commit changes (Conventional Commits)
git commit -m "feat(scope): {description} ##issue"

# Push and create PR
git push -u origin branch
```

### Issue Management
- Issues are stored in `.github/issues/` (Markdown files)
- Use `sync-issues.ps1` to sync with GitHub
- Labels: `bug`, `feature`, `docs`, `refactor`, `agent`

### Code Standards
- Follow existing code style in the project
- Run `# See package.json or .eslintrc` before committing
- Ensure tests pass before submitting PR

---

## 🔗 Resources & Links

| Resource | URL/Path |
|----------|----------|
| Documentation | ./docs |
| Repository | N/A |
| Issue Tracker | ./.github/issues |
| CI/CD | N/A |

---

## ⚠️ Important Notes for Claude Code

1. **Always read `.gitcore/ARCHITECTURE.md`** before making significant changes
2. **Maintain stateless design** - use GitHub Issues for state management
3. **Use type annotations** where available (TypeScript, Rust, Python type hints)
4. **Preserve backward compatibility** unless explicitly told otherwise
5. **Run full test suite** before marking tasks complete

### Files to Read First
- `.gitcore/ARCHITECTURE.md` - System design and architecture
- `README.md` - Project overview and setup instructions
- `package.json or config.*` - Configuration documentation

### Common Pitfalls
- Verify all changes compile before committing
- Run tests locally

---

## 📝 Changelog

| Date | Version | Changes |
|------|---------|---------|
| 2026-03-23 | 1.0.0 | Initial CLAUDE.md created |

---

*This file is maintained by SWAL Agent System*
*Last updated: 2026-03-23*
