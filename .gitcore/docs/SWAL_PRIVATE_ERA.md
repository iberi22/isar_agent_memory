# GitCore 3.8 — Private SWAL era policy

**Date:** 2026-07-17  
**Applies to:** all SWAL product and platform repositories

## 1. Visibility

- Default: **private** GitHub repositories.
- Public only with explicit ADR + license review (e.g. future intentional OSS).
- Local monorepo path `E:\proyectosSWAL` may hold many checkouts; remotes should be private.

## 2. GitHub Actions

- **Disabled by default.**
- Active path: `.github/workflows.disabled/` (not executed by GitHub).
- Prefer local: `cargo test`, `pnpm test`, project scripts.
- Re-enable a workflow only with written exception in `.gitcore/ARCHITECTURE.md`.

## 3. SRS + SRC (mandatory 100% structure)

| Artifact | Complete when |
|----------|----------------|
| `SRC.md` | Overview, tree, components, build/test, env, SWAL table, cross-links |
| `docs/SRS/index.md` | Status table + doc list |
| `docs/SRS/REQUIREMENTS.md` | ≥ REQ-001…007 baseline + domain REQs; each has Files + Acceptance |
| `docs/SRS/ARCHITECTURE.md` | Context diagram + non-negotiables + components |

Content may start as `draft` but **files and sections must exist**. Agents must improve traces to `synced`.

## 4. Agent files always maintained

| File | Rule |
|------|------|
| `AGENTS.md` | 7-step read order; Xavier MCP+HTTP; private era |
| `.gitcore/ARCHITECTURE.md` | Non-negotiables including SWAL product rules when app |
| `.gitcore/AGENT_INDEX.md` | Routing |
| `.gitcore/planning/*` | Session + scope |
| `.gitcore/features.json` | Feature list |
| `.cursorrules` / `.windsurfrules` | If used by IDE agents — keep protocol version aligned |

## 5. Xavier MCP

While agents connect Xavier MCP:

- Prefer MCP tools for durable memory when available.
- Fallback HTTP `http://127.0.0.1:8006` with token.
- Document endpoint in project `SRC.md` / `AGENTS.md`.
- Do not block local work if MCP is mid-setup; record connection status in TASK.md.

## 6. Forbidden product patterns

- Stripe (or similar) as **Pro unlock** for SWAL features.
- Merging two app instances’ business data without explicit link.
- Committing secrets.
- Re-enabling noisy scheduled GH Actions on private repos without need.

## 7. Scripts

```powershell
pwsh GitCore/scripts/swal-disable-workflows.ps1 -Root E:\proyectosSWAL
pwsh GitCore/scripts/swal-sync-gitcore.ps1 -Root E:\proyectosSWAL -PriorityOnly
pwsh GitCore/scripts/swal-ensure-srs-src.ps1 -Root E:\proyectosSWAL -PriorityOnly
pwsh GitCore/scripts/swal-set-repos-private.ps1  # requires gh
```
