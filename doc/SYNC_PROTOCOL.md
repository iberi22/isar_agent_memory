# Synchronization Protocol Design

## Overview

This document outlines the design for synchronizing `isar_agent_memory` data across multiple applications or devices. The goal is to enable a unified memory graph while maintaining privacy and offline-first capabilities.

## Architecture

We adopt a **Server-Relay** architecture where the server acts as a dumb store for encrypted blobs, or a **Peer-to-Peer** architecture (optional future). For Phase 1, we assume a central sync server or cloud storage (e.g., Firebase, AWS S3, or a custom Go/Rust binary).

### 1. Privacy (Client-Side Encryption)

- **Key Management**: Each user has a master synchronization key generated on the client.
- **Encryption**: All data (node content, edge metadata, embeddings) is encrypted *before* leaving the device using AES-256-GCM.
- **Embeddings**: Vector embeddings are also encrypted. For server-side vector search (if desired), we would need homomorphic encryption or a trusted enclave, but for this protocol, we assume search happens on-device or the server only stores blobs.
- **Metadata**: Only minimal unencrypted metadata (IDs, timestamps, version hashes) is exposed for reconciliation.

### 2. Versioning & Conflict Resolution

We use **Hybrid Logical Clocks (HLC)** or a simplified **Last-Write-Wins (LWW)** strategy backed by Merkle Trees for efficient diffing.

#### Data Model Extensions

Every `MemoryNode` and `MemoryEdge` will track:
- `modifiedAt`: UTC timestamp.
- `version`: Monotonic counter or HLC.
- `deviceId`: ID of the device that made the last change.
- `isDeleted`: Soft delete flag (tombstone).

#### Reconciliation Strategy (LWW)

1. **Pull**: Device requests changes since `lastSyncTimestamp`.
2. **Merge**:
   - If incoming record ID does not exist locally -> Insert.
   - If exists:
     - If `incoming.modifiedAt > local.modifiedAt` -> Overwrite.
     - If `incoming.modifiedAt < local.modifiedAt` -> Ignore.
     - If equal -> deterministic tie-break (e.g., compare `deviceId`).

### 3. Semantic Deduplication

To prevent duplicate memories when multiple devices observe similar events:

1. **On Ingest**: Before saving a new node, generate its embedding.
2. **Check**: Query the local vector index for nearest neighbors (threshold e.g., distance < 0.05).
3. **Decision**:
   - If a match is found: Merge/Update the existing node (e.g., update `lastAccessed`, add new metadata) instead of creating a new one.
   - If no match: Create new node.

## Implementation Plan

### Phase 1: Local Semantic Deduplication (Implemented)
- Modify `storeNodeWithEmbedding` to accept a `deduplicate` flag.
- Perform `semanticSearch` with `topK=1`.
- If `distance < threshold`, return existing ID.

### Phase 2: Cloud Sync (Planned)
- Serialize entities to JSON/Protobuf.
- Encrypt payload.
- Upload/Download flow.
