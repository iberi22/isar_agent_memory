# GitCore Protocol Template v3.8.0

> Template repo for SWAL development workflow.  
> GitCore is a **PROTOCOL** — not a product app.  
> **Updated:** 2026-07-17 — Private SWAL era

## Core

| Path | Purpose |
|------|---------|
| `.gitcore/ARCHITECTURE.md` | Non-negotiable decisions |
| `.gitcore/features.json` | Feature tracking |
| `.gitcore/planning/` | PLANNING.md + TASK.md |
| `AGENTS.md` | Agent read order + rules |
| `SRC.md` | Source Code Reference (**mandatory, complete**) |
| `docs/SRS/` | Software Requirements Spec (**mandatory, 100% structure**) |
| Xavier MCP/HTTP | Persistent agent memory |

## Principles (v3.8)

1. **Issues** = long-term state (local `.github/issues` OK when GH Actions off)
2. **TASK.md** = session state
3. **git + gh** = primary interface
4. **Xavier** = memory (HTTP `:8006` and/or **MCP**)
5. **Commits** = conventional + issue refs
6. **Repos private by default** (SWAL, until explicitly public)
7. **GitHub Actions disabled by default** (workflows live in `.github/workflows.disabled/`)
8. **SRS + SRC always present and complete** (definition of done for protocol compliance)
9. **Pro features in apps** = active SWAL node — not Stripe (see monorepo `docs/SWAL/README.md`)

## Version

**3.8.0** (2026-07-17)

### Breaking / policy changes from 3.7

| Topic | 3.7 | 3.8 |
|-------|-----|-----|
| Visibility | Mixed / adaptive CI | **Private default** |
| CI | Active workflows copied on install | **Workflows disabled**; optional re-enable |
| SRS | Optional post-read | **Mandatory 100% skeleton + fill** |
| SRC | Recommended | **Mandatory complete** |
| Xavier | HTTP curl examples | **HTTP + MCP** first-class |
| SWAL product rules | Not in protocol | **Linked** (node Pro, instance isolation) |

## Completeness gates (must be 100%)

### SRC.md complete when it has:

1. Overview / purpose of the repo  
2. Directory tree (real modules)  
3. Core components table  
4. Build / run / test commands  
5. Env vars (no secrets)  
6. Cross-links to `.gitcore/*`, `docs/SRS/*`, `AGENTS.md`  
7. Protocol version footer  

### docs/SRS/ complete when it has:

1. `index.md` — status table, doc list, synced ratio target  
2. `REQUIREMENTS.md` — REQ-IDs with acceptance criteria + file traces  
3. `ARCHITECTURE.md` — component map + non-functionals summary  
4. Optional: `NON-FUNCTIONAL.md`, `INTERFACES.md`, `DATABASE.md` if domain needs them  
5. Target: **synced ratio 100%** once drift tooling runs; until then `draft` is OK if every REQ has Files + Acceptance  

## Install / upgrade (local monorepo)

```powershell
# From monorepo root
pwsh .\GitCore\scripts\swal-sync-gitcore.ps1 -ProjectPath "E:\proyectosSWAL\shelf"
pwsh .\GitCore\scripts\swal-disable-workflows.ps1 -Root "E:\proyectosSWAL"
pwsh .\GitCore\scripts\swal-ensure-srs-src.ps1 -Root "E:\proyectosSWAL"
```
