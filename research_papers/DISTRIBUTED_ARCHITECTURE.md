# 🌐 Baby LLM: Arquitectura Distribuida Multi-Nodo

## Extensión del Plan: Red Distribuida PC + Móvil + Blockchain

Este documento extiende el plan original agregando:
1. **Arquitectura multi-nodo** (PC como "cerebro potente" + Móvil como "cerebro portable")
2. **Sincronización via blockchain local** (historial de pensamientos inmutable)
3. **Entrenamiento federado distribuido** (cada nodo contribuye según sus recursos)
4. **Componentes críticos en Rust** con paralelismo masivo

---

## 🏗️ Arquitectura de Red Distribuida

### Visión General: "Cerebro Distribuido"

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        BABY LLM DISTRIBUTED BRAIN                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      LOCAL NETWORK (LAN/WiFi)                        │   │
│  │                                                                      │   │
│  │   ┌─────────────────┐          ┌─────────────────┐                  │   │
│  │   │   🖥️ PC NODE     │◄────────►│  📱 MOBILE NODE │                  │   │
│  │   │   (Heavy Brain)  │   P2P    │  (Portable Brain)│                  │   │
│  │   │                  │  Sync    │                  │                  │   │
│  │   │ - Phi-3 (7B) Q4  │          │ - SmolLM-360M    │                  │   │
│  │   │ - Full training  │          │ - Light inference│                  │   │
│  │   │ - GPU accel      │          │ - On-device data │                  │   │
│  │   │ - 32GB+ RAM      │          │ - 4-8GB RAM      │                  │   │
│  │   └────────┬─────────┘          └────────┬─────────┘                  │   │
│  │            │                             │                            │   │
│  │            └─────────────┬───────────────┘                            │   │
│  │                          │                                            │   │
│  │                          ▼                                            │   │
│  │            ┌─────────────────────────────┐                            │   │
│  │            │   🔗 THOUGHT CHAIN          │                            │   │
│  │            │   (Local Blockchain)        │                            │   │
│  │            │                             │                            │   │
│  │            │   - Immutable thought log   │                            │   │
│  │            │   - Memory sync state       │                            │   │
│  │            │   - Learning checkpoints    │                            │   │
│  │            │   - Conflict resolution     │                            │   │
│  │            └─────────────────────────────┘                            │   │
│  │                                                                      │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                    SHARED MEMORY LAYER                                │  │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────────┐ │  │
│  │  │  Episodic  │  │  Semantic  │  │ Procedural │  │  LoRA Adapters │ │  │
│  │  │  Memories  │  │   Facts    │  │   Skills   │  │  (Personalized)│ │  │
│  │  │  (events)  │  │ (knowledge)│  │  (how-to)  │  │   Weights      │ │  │
│  │  └────────────┘  └────────────┘  └────────────┘  └────────────────┘ │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🔗 ThoughtChain: Blockchain Local de Pensamientos

### ¿Por qué Blockchain?

| Problema | Solución con Blockchain |
|----------|------------------------|
| Sincronización de memorias entre dispositivos | Estado compartido inmutable |
| Historial de "pensamientos" del modelo | Log auditable y permanente |
| Conflictos de actualización | Consenso determinístico |
| Integridad de datos | Hash criptográfico |
| Versionado de LoRA adapters | Checkpoints en cadena |

### Arquitectura de ThoughtChain

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           THOUGHTCHAIN STRUCTURE                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Block N-2          Block N-1          Block N            Block N+1         │
│  ┌──────────┐      ┌──────────┐      ┌──────────┐      ┌──────────┐        │
│  │ Header   │      │ Header   │      │ Header   │      │ Header   │        │
│  │ ├─prev_h │◄─────┤ ├─prev_h │◄─────┤ ├─prev_h │◄─────┤ ├─prev_h │        │
│  │ ├─timestamp     │ ├─timestamp     │ ├─timestamp     │ ├─timestamp       │
│  │ ├─merkle_root   │ ├─merkle_root   │ ├─merkle_root   │ ├─merkle_root     │
│  │ └─node_id│      │ └─node_id│      │ └─node_id│      │ └─node_id│        │
│  ├──────────┤      ├──────────┤      ├──────────┤      ├──────────┤        │
│  │ Payload  │      │ Payload  │      │ Payload  │      │ Payload  │        │
│  │          │      │          │      │          │      │          │        │
│  │ • Memory │      │ • Memory │      │ • LoRA   │      │ • Memory │        │
│  │   deltas │      │   deltas │      │   checkpoint    │   deltas │        │
│  │ • Thought│      │ • Learning      │ • Metrics│      │ • Thought│        │
│  │   logs   │      │   event  │      │          │      │   logs   │        │
│  └──────────┘      └──────────┘      └──────────┘      └──────────┘        │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Tipos de Bloques

```rust
// Rust: ThoughtChain block types

#[derive(Serialize, Deserialize, Clone)]
pub enum BlockPayload {
    /// Delta de memorias (nuevas, modificadas, eliminadas)
    MemoryDelta {
        added: Vec<MemoryNodeCompact>,
        modified: Vec<MemoryNodeCompact>,
        deleted: Vec<MemoryId>,
        embeddings_hash: [u8; 32],
    },
    
    /// Registro de "pensamiento" (interacción procesada)
    ThoughtLog {
        input_hash: [u8; 32],      // Hash del input (privacidad)
        output_hash: [u8; 32],     // Hash del output
        memory_refs: Vec<MemoryId>, // Memorias usadas
        model_used: ModelId,
        latency_ms: u32,
        confidence: f32,
    },
    
    /// Checkpoint de LoRA adapter
    LoRACheckpoint {
        adapter_id: Uuid,
        weights_hash: [u8; 32],
        training_samples: u64,
        loss: f32,
        parent_checkpoint: Option<[u8; 32]>,
    },
    
    /// Evento de aprendizaje (entrenamiento completado)
    LearningEvent {
        event_type: LearningEventType,
        samples_processed: u64,
        metrics: HashMap<String, f32>,
        node_id: NodeId,
    },
    
    /// Sincronización de estado entre nodos
    SyncState {
        node_states: HashMap<NodeId, NodeState>,
        consensus_round: u64,
    },
}

#[derive(Serialize, Deserialize, Clone)]
pub struct ThoughtBlock {
    pub header: BlockHeader,
    pub payload: BlockPayload,
    pub signature: Signature,
}

#[derive(Serialize, Deserialize, Clone)]
pub struct BlockHeader {
    pub version: u8,
    pub prev_hash: [u8; 32],
    pub timestamp: u64,
    pub merkle_root: [u8; 32],
    pub node_id: NodeId,
    pub block_type: BlockType,
    pub nonce: u64,  // Simple PoW for ordering
}
```

### Consenso: Proof of Authority + Timestamp

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        CONSENSUS PROTOCOL                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  MODELO: Proof of Authority (PoA) + Logical Clock                          │
│                                                                             │
│  1. Cada nodo es "autoridad" (no hay nodos maliciosos, es tu red)          │
│  2. Los bloques se ordenan por timestamp + nonce                           │
│  3. Conflictos se resuelven por:                                           │
│     a) Timestamp más reciente gana                                         │
│     b) Si empate: hash más bajo gana                                       │
│     c) Si empate: merge automático de deltas                               │
│                                                                             │
│  SINCRONIZACIÓN:                                                            │
│  ┌─────────────┐                              ┌─────────────┐              │
│  │   PC Node   │ ────── Request Sync ──────► │ Mobile Node │              │
│  │             │ ◄───── Block Headers ────── │             │              │
│  │             │ ────── Request Blocks ────► │             │              │
│  │             │ ◄───── Block Data ───────── │             │              │
│  │             │ ────── ACK + New Blocks ──► │             │              │
│  └─────────────┘                              └─────────────┘              │
│                                                                             │
│  CONFLICT RESOLUTION (para memorias):                                       │
│  - Last Write Wins (LWW) con vector clock                                  │
│  - Merge automático para memorias no conflictivas                          │
│  - Alerta al usuario para conflictos semánticos                            │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🎓 Entrenamiento Federado Distribuido

### Arquitectura de Flower-Inspired Federated Learning

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    FEDERATED LEARNING ARCHITECTURE                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                        TRAINING ORCHESTRATOR                         │   │
│  │                    (Runs on most powerful node)                      │   │
│  │                                                                      │   │
│  │  ┌────────────────────────────────────────────────────────────────┐ │   │
│  │  │                    FEDERATED AGGREGATOR                         │ │   │
│  │  │                                                                 │ │   │
│  │  │  1. Distribute current model/adapter weights to nodes           │ │   │
│  │  │  2. Each node trains locally on its data                        │ │   │
│  │  │  3. Nodes send weight gradients (not data!) back                │ │   │
│  │  │  4. Aggregator merges gradients (FedAvg, FedProx, etc.)        │ │   │
│  │  │  5. Updated weights distributed to all nodes                    │ │   │
│  │  │  6. Checkpoint saved to ThoughtChain                           │ │   │
│  │  └────────────────────────────────────────────────────────────────┘ │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│         ┌──────────────────┬──────────────────┬──────────────────┐         │
│         │                  │                  │                  │         │
│         ▼                  ▼                  ▼                  ▼         │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐ │
│  │  PC Node    │    │ Mobile Node │    │ Tablet Node │    │ Future Node │ │
│  │  (Primary)  │    │ (Secondary) │    │ (Optional)  │    │ (Extensible)│ │
│  │             │    │             │    │             │    │             │ │
│  │ Training:   │    │ Training:   │    │ Training:   │    │ Training:   │ │
│  │ - Full LoRA │    │ - Micro LoRA│    │ - Mini LoRA │    │ - Adaptive  │ │
│  │ - Batch: 32 │    │ - Batch: 4  │    │ - Batch: 8  │    │ - Dynamic   │ │
│  │ - GPU accel │    │ - CPU only  │    │ - CPU/NPU   │    │             │ │
│  │             │    │             │    │             │    │             │ │
│  │ Data:       │    │ Data:       │    │ Data:       │    │ Data:       │ │
│  │ - Web hist  │    │ - Phone data│    │ - App usage │    │ - Any       │ │
│  │ - Documents │    │ - Messages  │    │ - Notes     │    │             │ │
│  │ - Code      │    │ - Contacts  │    │ - Calendar  │    │             │ │
│  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘ │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Adaptive Training basado en Recursos

```rust
// Rust: Adaptive training scheduler

pub struct AdaptiveTrainer {
    device_profile: DeviceProfile,
    battery_monitor: BatteryMonitor,
    memory_monitor: MemoryMonitor,
    thermal_monitor: ThermalMonitor,
}

impl AdaptiveTrainer {
    /// Determina configuración óptima de entrenamiento
    pub async fn get_training_config(&self) -> TrainingConfig {
        let battery = self.battery_monitor.current_level();
        let memory_free = self.memory_monitor.available_mb();
        let temperature = self.thermal_monitor.cpu_temp();
        let is_charging = self.battery_monitor.is_charging();
        let is_idle = self.device_profile.is_user_idle();
        
        // Reglas de decisión
        let config = match (battery, is_charging, is_idle, temperature) {
            // Modo agresivo: cargando, idle, temperatura OK
            (_, true, true, t) if t < 40.0 => TrainingConfig {
                batch_size: self.device_profile.max_batch_size(),
                learning_rate: 1e-4,
                gradient_accumulation: 1,
                max_training_time: Duration::from_secs(3600),
                priority: TrainingPriority::High,
            },
            
            // Modo moderado: buena batería, no idle
            (b, _, false, t) if b > 50 && t < 45.0 => TrainingConfig {
                batch_size: self.device_profile.max_batch_size() / 2,
                learning_rate: 5e-5,
                gradient_accumulation: 2,
                max_training_time: Duration::from_secs(300),
                priority: TrainingPriority::Medium,
            },
            
            // Modo conservador: batería baja o temperatura alta
            (b, false, _, _) if b < 30 => TrainingConfig {
                batch_size: 1,
                learning_rate: 0.0,  // No training
                gradient_accumulation: 0,
                max_training_time: Duration::ZERO,
                priority: TrainingPriority::Disabled,
            },
            
            // Modo mínimo: cualquier otro caso
            _ => TrainingConfig {
                batch_size: 2,
                learning_rate: 1e-5,
                gradient_accumulation: 4,
                max_training_time: Duration::from_secs(60),
                priority: TrainingPriority::Low,
            },
        };
        
        config
    }
    
    /// Ejecuta entrenamiento adaptativo en background
    pub async fn background_train(&self, data: TrainingData) -> TrainingResult {
        loop {
            let config = self.get_training_config().await;
            
            if config.priority == TrainingPriority::Disabled {
                // Esperar hasta que las condiciones mejoren
                tokio::time::sleep(Duration::from_secs(60)).await;
                continue;
            }
            
            // Entrenar un mini-batch
            let result = self.train_step(&config, &data).await?;
            
            // Verificar si debemos parar
            if self.should_pause().await {
                return result;
            }
            
            // Reportar progreso al orquestador
            self.report_progress(&result).await;
        }
    }
}
```

### LoRA Adapter Merging

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        LORA ADAPTER FEDERATION                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Cada nodo entrena su propio LoRA adapter con datos locales:               │
│                                                                             │
│  PC Node LoRA          Mobile LoRA         Tablet LoRA                     │
│  (rank=16)             (rank=4)            (rank=8)                        │
│  ┌─────────┐           ┌─────────┐         ┌─────────┐                     │
│  │ΔW_pc    │           │ΔW_mobile│         │ΔW_tablet│                     │
│  │= A_pc   │           │= A_mob  │         │= A_tab  │                     │
│  │  × B_pc │           │  × B_mob│         │  × B_tab│                     │
│  └────┬────┘           └────┬────┘         └────┬────┘                     │
│       │                     │                   │                          │
│       └─────────────────────┼───────────────────┘                          │
│                             │                                               │
│                             ▼                                               │
│                   ┌─────────────────┐                                       │
│                   │   AGGREGATOR    │                                       │
│                   │                 │                                       │
│                   │  ΔW_merged =    │                                       │
│                   │    α₁·ΔW_pc +   │                                       │
│                   │    α₂·ΔW_mob +  │                                       │
│                   │    α₃·ΔW_tab    │                                       │
│                   │                 │                                       │
│                   │  where αᵢ =     │                                       │
│                   │  samples_i /    │                                       │
│                   │  total_samples  │                                       │
│                   └────────┬────────┘                                       │
│                            │                                                │
│                            ▼                                                │
│                   ┌─────────────────┐                                       │
│                   │  MERGED LORA    │                                       │
│                   │  (distributed   │                                       │
│                   │   to all nodes) │                                       │
│                   └─────────────────┘                                       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🦀 Componentes Rust de Alto Rendimiento

### Módulos Críticos a Implementar

```rust
// baby_llm_core/src/lib.rs

/// Core modules implementados en Rust con paralelismo
pub mod core {
    pub mod memory {
        pub mod working_memory;      // Lock-free circular buffer (crossbeam)
        pub mod consolidation;       // Parallel sleep-like consolidation (rayon)
        pub mod forgetting;          // SIMD-accelerated importance decay
        pub mod retrieval;           // Parallel HNSW search (rayon)
    }
    
    pub mod blockchain {
        pub mod thought_chain;       // Local blockchain implementation
        pub mod consensus;           // PoA + timestamp consensus
        pub mod sync;                // P2P block synchronization
        pub mod merkle;              // Merkle tree for memory verification
    }
    
    pub mod network {
        pub mod discovery;           // mDNS/DNS-SD node discovery
        pub mod p2p;                 // libp2p-based P2P layer
        pub mod sync_protocol;       // Delta sync protocol
        pub mod encryption;          // End-to-end encryption (noise protocol)
    }
    
    pub mod training {
        pub mod federated;           // Federated learning coordinator
        pub mod lora;                // LoRA adapter training
        pub mod gradient;            // Gradient compression & aggregation
        pub mod scheduler;           // Adaptive training scheduler
    }
    
    pub mod inference {
        pub mod engine;              // llama.cpp/candle inference
        pub mod router;              // Model routing (fast vs deep)
        pub mod kv_cache;            // KV-cache management
        pub mod speculative;         // Speculative decoding
    }
    
    pub mod scraping {
        pub mod android;             // JNI bindings for Android
        pub mod ios;                 // FFI bindings for iOS
        pub mod desktop;             // Desktop data sources
        pub mod normalizer;          // Cross-platform data normalization
    }
    
    pub mod embeddings {
        pub mod onnx;                // ONNX Runtime inference
        pub mod batch;               // SIMD batch processing
        pub mod quantized;           // INT8 quantized embeddings
    }
}
```

### Ejemplo: P2P Sync Protocol

```rust
use libp2p::{
    gossipsub, mdns, noise, tcp, yamux,
    swarm::{NetworkBehaviour, Swarm},
    PeerId, Multiaddr,
};
use tokio::sync::mpsc;

#[derive(NetworkBehaviour)]
pub struct BabyLLMBehaviour {
    gossipsub: gossipsub::Behaviour,
    mdns: mdns::tokio::Behaviour,
}

pub struct P2PNode {
    swarm: Swarm<BabyLLMBehaviour>,
    thought_chain: Arc<RwLock<ThoughtChain>>,
    memory_store: Arc<RwLock<MemoryStore>>,
}

impl P2PNode {
    pub async fn new(keypair: Keypair) -> Result<Self, P2PError> {
        let peer_id = PeerId::from(keypair.public());
        
        // Configure transport with encryption
        let transport = tcp::tokio::Transport::default()
            .upgrade(Version::V1)
            .authenticate(noise::Config::new(&keypair)?)
            .multiplex(yamux::Config::default())
            .boxed();
        
        // Configure gossipsub for block propagation
        let gossipsub_config = gossipsub::ConfigBuilder::default()
            .heartbeat_interval(Duration::from_secs(10))
            .validation_mode(gossipsub::ValidationMode::Strict)
            .build()?;
        
        let gossipsub = gossipsub::Behaviour::new(
            gossipsub::MessageAuthenticity::Signed(keypair.clone()),
            gossipsub_config,
        )?;
        
        // Configure mDNS for local discovery
        let mdns = mdns::tokio::Behaviour::new(
            mdns::Config::default(),
            peer_id,
        )?;
        
        let behaviour = BabyLLMBehaviour { gossipsub, mdns };
        let swarm = Swarm::new(transport, behaviour, peer_id);
        
        Ok(Self {
            swarm,
            thought_chain: Arc::new(RwLock::new(ThoughtChain::new())),
            memory_store: Arc::new(RwLock::new(MemoryStore::new())),
        })
    }
    
    /// Broadcast new block to all peers
    pub async fn broadcast_block(&mut self, block: ThoughtBlock) -> Result<(), P2PError> {
        let topic = gossipsub::IdentTopic::new("thoughtchain");
        let message = bincode::serialize(&block)?;
        
        self.swarm
            .behaviour_mut()
            .gossipsub
            .publish(topic, message)?;
        
        Ok(())
    }
    
    /// Request sync with a specific peer
    pub async fn request_sync(&mut self, peer: PeerId) -> Result<SyncResult, P2PError> {
        let my_head = self.thought_chain.read().await.head_hash();
        
        // Send sync request
        let request = SyncRequest {
            my_head,
            my_height: self.thought_chain.read().await.height(),
        };
        
        // ... P2P request/response logic ...
        
        Ok(SyncResult::default())
    }
    
    /// Main event loop
    pub async fn run(&mut self) {
        loop {
            tokio::select! {
                event = self.swarm.select_next_some() => {
                    self.handle_swarm_event(event).await;
                }
            }
        }
    }
}
```

### Ejemplo: Parallel Memory Consolidation

```rust
use rayon::prelude::*;
use std::sync::atomic::{AtomicU64, Ordering};

pub struct ParallelConsolidator {
    memory_store: Arc<RwLock<MemoryStore>>,
    embeddings_cache: Arc<DashMap<MemoryId, Vec<f32>>>,
    llm_adapter: Arc<dyn LLMAdapter>,
}

impl ParallelConsolidator {
    /// Sleep-like consolidation with parallel processing
    pub async fn consolidate(&self, config: ConsolidationConfig) -> ConsolidationReport {
        let start = Instant::now();
        let memories = self.memory_store.read().await.get_unconsolidated();
        
        // Parallel importance scoring
        let scored: Vec<(MemoryId, f32)> = memories
            .par_iter()
            .map(|m| {
                let importance = self.calculate_importance_simd(m);
                (m.id, importance)
            })
            .collect();
        
        // Filter important memories
        let important: Vec<_> = scored
            .into_par_iter()
            .filter(|(_, score)| *score > config.importance_threshold)
            .collect();
        
        // Parallel clustering using HNSW
        let clusters = self.parallel_cluster(&important, config.similarity_threshold);
        
        // Generate abstractions in parallel (but with LLM batching)
        let abstractions = self.batch_abstract(&clusters).await;
        
        // Atomic counters for stats
        let processed = AtomicU64::new(0);
        let consolidated = AtomicU64::new(0);
        
        // Parallel integration
        abstractions.par_iter().for_each(|abstraction| {
            processed.fetch_add(1, Ordering::Relaxed);
            
            if let Ok(_) = self.integrate_abstraction(abstraction) {
                consolidated.fetch_add(1, Ordering::Relaxed);
            }
        });
        
        // Parallel decay of processed memories
        important.par_iter().for_each(|(id, _)| {
            let _ = self.apply_decay(*id, config.decay_factor);
        });
        
        ConsolidationReport {
            duration: start.elapsed(),
            memories_processed: processed.load(Ordering::Relaxed),
            abstractions_created: consolidated.load(Ordering::Relaxed),
            clusters_found: clusters.len() as u64,
        }
    }
    
    /// SIMD-accelerated importance calculation
    #[cfg(target_arch = "x86_64")]
    fn calculate_importance_simd(&self, memory: &MemoryNode) -> f32 {
        use std::arch::x86_64::*;
        
        unsafe {
            // Pack factors into SIMD registers
            let factors = _mm256_set_ps(
                memory.recency_score(),
                memory.access_count as f32 / 10.0,
                memory.connection_count as f32 / 5.0,
                memory.explicit_importance,
                memory.emotional_valence.abs(),
                memory.relevance_score,
                0.0, 0.0
            );
            
            // Weights
            let weights = _mm256_set_ps(
                0.25, 0.20, 0.15, 0.15, 0.10, 0.15, 0.0, 0.0
            );
            
            // Multiply and sum
            let product = _mm256_mul_ps(factors, weights);
            
            // Horizontal sum
            let sum = hsum_ps_avx(product);
            sum.min(1.0).max(0.0)
        }
    }
}
```

---

## 📱 Onboarding del Dispositivo (Scraping)

### Fuentes de Datos por Plataforma

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      DATA SOURCES PER PLATFORM                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  📱 ANDROID (Más abierto)                    🍎 iOS (Más restrictivo)       │
│  ─────────────────────────                   ─────────────────────────      │
│                                                                             │
│  ✅ Contactos (ContactsContract)             ✅ Contactos (CNContactStore)  │
│  ✅ Calendario (CalendarContract)            ✅ Calendario (EventKit)       │
│  ✅ App Usage (UsageStatsManager)            ⚠️ Screen Time (limitado)      │
│  ✅ Notificaciones (NotificationListener)    ❌ Solo propias                │
│  ⚠️ SMS (Play Store restrictivo)             ❌ No disponible               │
│  ⚠️ Llamadas (Play Store restrictivo)        ❌ No disponible               │
│  ✅ Ubicación (FusedLocation)                ⚠️ Ubicación (CLLocation)      │
│  ✅ Fotos EXIF (MediaStore)                  ✅ Fotos (PHPhotoLibrary)      │
│  ✅ WiFi guardadas                           ⚠️ NEHotspotConfiguration      │
│  ✅ Bluetooth paired                         ✅ CBCentralManager            │
│  ✅ Clipboard (foreground)                   ✅ UIPasteboard (foreground)   │
│  ⚠️ Accessibility (muy poderoso)             ❌ Muy limitado                │
│  ✅ Files (Documents, Downloads)             ✅ Files (Documents)           │
│                                                                             │
│  🖥️ DESKTOP (Windows/Linux/macOS)                                          │
│  ─────────────────────────────────                                          │
│                                                                             │
│  ✅ Browser history (Chrome, Firefox, Edge, Safari)                        │
│  ✅ Documents (PDF, Office, TXT, MD)                                        │
│  ✅ Code repositories (Git history, file changes)                          │
│  ✅ Email (IMAP/local clients)                                              │
│  ✅ Calendar (local .ics, Exchange, Google Calendar)                       │
│  ✅ Notes (Obsidian, Notion exports, Apple Notes)                          │
│  ✅ Chat exports (Slack, Discord, Telegram)                                │
│  ✅ Bookmarks                                                               │
│  ✅ Application usage (with user permission)                               │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Pipeline de Onboarding Paralelo

```rust
// Rust: Parallel onboarding pipeline

pub struct OnboardingPipeline {
    scrapers: Vec<Box<dyn DataScraper>>,
    embeddings_engine: Arc<EmbeddingsEngine>,
    memory_store: Arc<RwLock<MemoryStore>>,
    thought_chain: Arc<RwLock<ThoughtChain>>,
    progress_tx: mpsc::Sender<OnboardingProgress>,
}

impl OnboardingPipeline {
    pub async fn run_full_onboarding(&self) -> OnboardingResult {
        let start = Instant::now();
        
        // Phase 1: Parallel data extraction
        let raw_data = self.parallel_extract().await?;
        
        // Phase 2: Parallel processing (chunking, embedding, classification)
        let processed = self.parallel_process(raw_data).await?;
        
        // Phase 3: Store in memory graph
        let stored = self.store_memories(processed).await?;
        
        // Phase 4: Record onboarding event in ThoughtChain
        self.record_onboarding_event(&stored).await?;
        
        // Phase 5: Generate initial user profile
        let profile = self.generate_profile().await?;
        
        OnboardingResult {
            duration: start.elapsed(),
            data_sources_processed: self.scrapers.len(),
            memories_created: stored.len(),
            profile,
        }
    }
    
    async fn parallel_extract(&self) -> Result<Vec<RawData>, OnboardingError> {
        let (results, errors): (Vec<_>, Vec<_>) = self.scrapers
            .par_iter()
            .map(|scraper| {
                self.progress_tx.blocking_send(OnboardingProgress {
                    phase: Phase::Extracting,
                    source: scraper.name(),
                    progress: 0.0,
                });
                
                scraper.extract()
            })
            .partition(Result::is_ok);
        
        let data: Vec<RawData> = results
            .into_iter()
            .flat_map(|r| r.unwrap())
            .collect();
        
        Ok(data)
    }
    
    async fn parallel_process(&self, raw: Vec<RawData>) -> Result<Vec<ProcessedMemory>, OnboardingError> {
        // Chunk into batches for efficient embedding
        let batches: Vec<_> = raw.chunks(100).collect();
        
        let processed: Vec<ProcessedMemory> = batches
            .par_iter()
            .flat_map(|batch| {
                // Embed batch
                let embeddings = self.embeddings_engine
                    .embed_batch(batch.iter().map(|d| d.content.as_str()).collect())
                    .unwrap_or_default();
                
                // Classify and create memories
                batch.iter()
                    .zip(embeddings.iter())
                    .map(|(data, embedding)| {
                        ProcessedMemory {
                            content: data.content.clone(),
                            embedding: embedding.clone(),
                            memory_type: self.classify_memory(&data),
                            source: data.source.clone(),
                            timestamp: data.timestamp,
                            metadata: data.metadata.clone(),
                        }
                    })
                    .collect::<Vec<_>>()
            })
            .collect();
        
        Ok(processed)
    }
}
```

---

## 📦 Estructura del Proyecto Actualizada

```
baby_llm/
├── 📁 dart/                              # Flutter apps
│   ├── baby_llm_mobile/                  # Mobile app (Android/iOS)
│   │   ├── lib/
│   │   │   ├── main.dart
│   │   │   ├── baby_llm.dart            # Mobile-specific orchestrator
│   │   │   ├── onboarding/              # Phone data onboarding
│   │   │   ├── ui/                      # Mobile UI
│   │   │   └── native/                  # FFI bindings
│   │   └── pubspec.yaml
│   │
│   ├── baby_llm_desktop/                 # Desktop app (Windows/Linux/macOS)
│   │   ├── lib/
│   │   │   ├── main.dart
│   │   │   ├── baby_llm.dart            # Desktop-specific orchestrator
│   │   │   ├── onboarding/              # Desktop data onboarding
│   │   │   ├── training/                # Training UI/controls
│   │   │   └── native/                  # FFI bindings
│   │   └── pubspec.yaml
│   │
│   └── baby_llm_shared/                  # Shared Dart code
│       ├── lib/
│       │   ├── models/
│       │   ├── services/
│       │   └── utils/
│       └── pubspec.yaml
│
├── 📁 rust/                              # Rust core (baby_llm_core)
│   ├── Cargo.toml
│   ├── src/
│   │   ├── lib.rs
│   │   ├── memory/                       # Memory management
│   │   ├── blockchain/                   # ThoughtChain
│   │   ├── network/                      # P2P networking
│   │   ├── training/                     # Federated learning
│   │   ├── inference/                    # LLM inference
│   │   ├── scraping/                     # Data extraction
│   │   └── embeddings/                   # Embedding generation
│   │
│   ├── crates/
│   │   ├── baby_llm_android/            # Android-specific builds
│   │   ├── baby_llm_ios/                # iOS-specific builds
│   │   └── baby_llm_desktop/            # Desktop-specific builds
│   │
│   └── build/
│       ├── android/                      # NDK build scripts
│       ├── ios/                          # Xcode build integration
│       └── desktop/                      # Platform builds
│
├── 📁 models/                            # Model files
│   ├── smollm-360m-q4.gguf              # Mobile fast brain (~250MB)
│   ├── phi3-mini-q4.gguf                # Desktop deep brain (~2GB)
│   ├── embeddings-mini.onnx             # Embeddings model (~50MB)
│   └── lora/                            # LoRA adapters directory
│       └── base_adapter.safetensors
│
├── 📁 isar_agent_memory/                 # Memory package (submodule)
│
├── 📁 protocols/                         # Protocol definitions
│   ├── thoughtchain.proto               # ThoughtChain block format
│   ├── sync.proto                       # Sync protocol
│   └── training.proto                   # Training protocol
│
└── 📁 docs/
    ├── ARCHITECTURE.md
    ├── DISTRIBUTED_NETWORK.md           # This file
    ├── ONBOARDING.md
    ├── TRAINING.md
    └── PRIVACY.md
```

---

## 🗓️ Roadmap Actualizado

### Fase 1: Core Foundation (6-8 semanas)
```
□ Setup proyecto Rust con flutter_rust_bridge
□ Implementar ThoughtChain básico (bloques, hash, storage)
□ P2P discovery con mDNS
□ Integración básica Flutter mobile + desktop
□ SmolLM-360M funcionando en ambas plataformas
```

### Fase 2: Memoria Distribuida (6-8 semanas)
```
□ Sync protocol para ThoughtChain
□ Memory delta sync entre nodos
□ Conflict resolution (LWW + vector clocks)
□ isar_agent_memory integración con sync
□ UI de estado de sincronización
```

### Fase 3: Onboarding Multi-plataforma (6-8 semanas)
```
□ Android scrapers (contactos, calendario, app usage)
□ iOS scrapers (contactos, calendario, fotos)
□ Desktop scrapers (browser history, documents, code)
□ Parallel processing pipeline en Rust
□ UI de onboarding con progreso
```

### Fase 4: Entrenamiento Federado (8-10 semanas)
```
□ LoRA training en PC
□ Micro-LoRA training en móvil (cuando hay recursos)
□ Gradient aggregation protocol
□ Adaptive training scheduler
□ Training checkpoints en ThoughtChain
```

### Fase 5: Dual-Brain + Routing (4-6 semanas)
```
□ Phi-3 integration en desktop
□ Query router (simple vs complex)
□ Speculative decoding
□ Model switching basado en contexto
```

### Fase 6: Polish & Security (4-6 semanas)
```
□ End-to-end encryption para P2P
□ Key management
□ Battery optimization
□ Testing extensivo
□ Documentación
□ Beta release
```

**Total estimado: 34-46 semanas (~8-11 meses)**

---

## 🔐 Consideraciones de Seguridad

### Modelo de Amenazas

| Amenaza | Mitigación |
|---------|------------|
| Datos en tránsito interceptados | E2E encryption (Noise Protocol) |
| Datos en reposo comprometidos | AES-256-GCM con key derivada |
| Nodo malicioso en red local | PoA + verificación de firma |
| Pérdida de dispositivo | Wipe remoto + key escrow opcional |
| Ataques de replay | Nonces + timestamps |

### Arquitectura de Privacidad

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         PRIVACY ARCHITECTURE                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  PRINCIPIO: Los datos NUNCA salen de tus dispositivos                      │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    DATA FLOW                                         │   │
│  │                                                                      │   │
│  │  Raw Data ──► Local Processing ──► Encrypted Storage                 │   │
│  │     │              │                    │                            │   │
│  │     │              ▼                    ▼                            │   │
│  │     │         Embeddings           ThoughtChain                      │   │
│  │     │         (vectors)            (hashed data)                     │   │
│  │     │              │                    │                            │   │
│  │     │              └─────────┬──────────┘                            │   │
│  │     │                        │                                       │   │
│  │     │                        ▼                                       │   │
│  │     │              Encrypted P2P Sync                                │   │
│  │     │              (between YOUR devices only)                       │   │
│  │     │                                                                │   │
│  │     ▼                                                                │   │
│  │  [DELETED]  ← Raw data se elimina después de procesar               │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  DATOS SENSIBLES:                                                          │
│  ────────────────                                                          │
│  - PII → Solo embeddings (no texto plano)                                  │
│  - Ubicaciones → Clusters aproximados                                      │
│  - Mensajes → Solo sentiment + topics (no contenido)                       │
│  - ThoughtChain → Solo hashes de inputs/outputs                            │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🎯 Conclusiones

### Viabilidad Técnica: ✅ VIABLE

1. **Red distribuida PC+Móvil**: Completamente viable usando libp2p/mDNS
2. **Blockchain local**: Viable y apropiado para sincronización determinística
3. **Entrenamiento federado**: Viable usando técnicas de Flower AI
4. **Rust para performance**: Esencial para P2P, sync, y training
5. **Modelo base vs desde cero**: **Modelo base (SmolLM/Phi-3)** es la única opción práctica

### Stack Tecnológico Final

| Componente | Tecnología |
|------------|------------|
| **Mobile UI** | Flutter |
| **Desktop UI** | Flutter |
| **Core Logic** | Rust |
| **FFI Bridge** | flutter_rust_bridge |
| **LLM Inference** | llama.cpp / Candle |
| **Embeddings** | ONNX Runtime |
| **P2P Network** | libp2p |
| **Discovery** | mDNS (dns-sd) |
| **Blockchain** | Custom (ThoughtChain) |
| **Memory Storage** | ObjectBox (isar_agent_memory) |
| **Training** | Custom LoRA + FedAvg |

### Próximo Paso Recomendado

Crear un **Proof of Concept** que demuestre:
1. P2P connection entre PC y móvil en LAN
2. ThoughtChain básico sincronizando entre dispositivos
3. SmolLM funcionando en ambos

**Tiempo estimado para PoC: 4-6 semanas**
