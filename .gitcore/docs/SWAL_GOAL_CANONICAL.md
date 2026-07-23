# SWAL — Goal unificado (fuente de verdad)

> **Leer primero en el monorepo.**  
> Copia operativa en cada proyecto: `.gitcore/docs/SWAL_GOAL.md` (via GitCore update).  
> **Actualizado:** 2026-07-17

## Una frase

**SWAL es una red de aplicaciones agentic (PWA) con nodo propio, memoria compartida (Xavier), mesh de datos (edge-mesh) y token $SWAL de propiedad de las personas — sin Stripe para Pro.**

## Goals (no negociables)

1. **Apps libres / usables en free** — el valor Pro es capacidad de red, no paywall fiat.  
2. **Pro = nodo SWAL activo** — heartbeat + identidad + (ideal) Xavier; **nunca Stripe/suscripción** como unlock Pro.  
3. **Xavier = memoria agentic** — fuera de la BD de negocio de cada app; HTTP y/o MCP.  
4. **edge-mesh = data plane** — CRDT/trabajo/telemetría; namespaces `swal/{appId}/{instanceId}`.  
5. **Instancias desacopladas** — dos installs de la misma app no mezclan datos por defecto.  
6. **$SWAL = ownership + yield** — stake genera % de interés desde fees de red (economic core / gara-g).  
7. **Datos de negocio en la app** — inventario, menús, SECOP, exámenes: **no** van a la chain en claro.  
8. **GitCore 3.8** — repos private, GH Actions off, SRC+SRS obligatorios, feature-verify para agentes.  
9. **Maloca = platform workspace** — `swal-backoffice` (shell multi-app) + `maloca-node` (dominio SECOP) + packages `@swal/*`.  
10. **Un solo canónico por capa** — edge-mesh, xavier, veedur SECOP, economic core; sin forks eternos.

## Qué NO es el goal

- Monolito que meta todas las BDs en un solo servicio.  
- Tres tokens cotizando (GARA / XAV / OMNI) — unificar narrativa en **$SWAL**.  
- Backoffice = dashboard de un solo producto (p. ej. solo SECOP).  
- Reintroducir Stripe para “planes Pro SWAL”.

## Mapa de lectura (orden)

| # | Doc | Quién |
|---|-----|--------|
| 1 | Este archivo `GOAL.md` | Todos |
| 2 | [README.md](./README.md) roadmap | Todos |
| 3 | [NODE_PRO_AND_INSTANCES.md](./NODE_PRO_AND_INSTANCES.md) | Apps producto |
| 4 | [PROJECT_MAP.md](./PROJECT_MAP.md) | Integración multi-repo |
| 5 | [GITCORE_SCRIPTS.md](./GITCORE_SCRIPTS.md) | Agentes / verify |
| 6 | `maloca/DESIGN.md` + ADR-001 backoffice | Platform |
| 7 | `GitCore/docs/SWAL_PRIVATE_ERA.md` | Protocolo |

## Frase para AGENTS.md de cada proyecto

```text
SWAL goal: docs/SWAL/GOAL.md (monorepo) · local: .gitcore/docs/SWAL_GOAL.md
Pro = SWAL node · Xavier memory · edge-mesh namespaces · no Stripe Pro · GitCore 3.8
Backoffice: maloca/apps/swal-backoffice · Platform packages: maloca/packages/@swal/*
```

## Si un proyecto se “desconecta”

Un proyecto está desalineado si:

- [ ] No menciona el goal SWAL ni `docs/SWAL`  
- [ ] Documenta Stripe/suscripción como Pro  
- [ ] Inventa su propio mesh/memory sin Xavier/edge-mesh  
- [ ] Mezcla instance_id sin opt-in  
- [ ] No tiene GitCore 3.8 / SRC+SRS  

**Acción:** `pwsh GitCore/scripts/swal-gitcore-update-all.ps1 -Force` y actualizar README/AGENTS con el bloque de arriba.
