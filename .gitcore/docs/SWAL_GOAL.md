# SWAL Goal (local copy — keep in sync via gitcore-update)

> **Canonical (monorepo):** `docs/SWAL/GOAL.md`  
> **Map:** `docs/SWAL/PROJECT_MAP.md`  
> **Roadmap:** `docs/SWAL/README.md`  
> **Protocol:** GitCore 3.8 · this file is managed by `gitcore-update.ps1`

## Goal (one sentence)

SWAL is a network of **agentic PWAs** with **owned $SWAL**, **Xavier memory**, **edge-mesh data plane**, and **Pro = active SWAL node** — **not Stripe**.

## Non-negotiables for THIS project

1. Free core usage; Pro requires **SWAL node active**.  
2. **No Stripe** (or similar) as Pro unlock.  
3. Business DB stays in this app; agentic memory → **Xavier** (`app/{appId}/instance/{id}`).  
4. Multi-instance data **decoupled** by default (`instance_id`).  
5. Mesh via **edge-mesh** namespaces `swal/{appId}/{instanceId}` when P2P applies.  
6. GitCore **3.8**: private repo default, workflows disabled, SRC + SRS complete.  
7. Platform shell: `maloca/apps/swal-backoffice` — do not invent a second multi-app admin.  
8. Token narrative: **$SWAL** (not parallel XAV/OMNI/GARA coins).

## Read order for agents on any SWAL project

```
1. .gitcore/docs/SWAL_GOAL.md     ← this file
2. AGENTS.md
3. .gitcore/ARCHITECTURE.md
4. SRC.md + docs/SRS/
5. monorepo docs/SWAL/GOAL.md + PROJECT_MAP.md (if available)
```

## If disconnected

Run from monorepo:

```powershell
$env:GITCORE_HOME = "E:\proyectosSWAL\GitCore"
pwsh E:\proyectosSWAL\GitCore\scripts\swal-gitcore-update-all.ps1 -Force
```

Then ensure README/AGENTS link this goal.
