# 🧒 Baby LLM: Arquitectura de Modelo Auto-Evolutivo con Memoria Biológica

## Resumen Ejecutivo

Este documento presenta el diseño de un modelo LLM "Baby" que:
1. **Aprende continuamente** de su entorno (dispositivo móvil)
2. **Replica sistemas de memoria biológica** (episódica, semántica, procedural)
3. **Usa Rust para componentes de alto rendimiento** con paralelismo
4. **Se ejecuta completamente on-device** (móvil)

---

## 📊 Análisis: ¿Desde Cero vs. Modelo Base?

### Opción A: Entrenar desde Cero

| Aspecto | Evaluación |
|---------|------------|
| **Viabilidad** | ❌ No recomendado |
| **Tiempo estimado** | 2-5 años para un equipo pequeño |
| **Costo computacional** | ~$1-10M USD en GPU/TPU |
| **Datos necesarios** | ~1-10TB de texto de alta calidad |
| **Resultado esperado** | Modelo inferior a alternativas existentes |

**Problemas fundamentales:**
- Un LLM desde cero requiere **billones de tokens** de pre-entrenamiento
- Los costos de entrenamiento son prohibitivos
- Sin emergent capabilities hasta ~7B parámetros

### Opción B: Modelo Base Pequeño + Fine-tuning Continuo ✅

| Modelo | Parámetros | RAM Móvil | Velocidad | Calidad |
|--------|------------|-----------|-----------|---------|
| **Phi-3-mini** | 3.8B | ~4GB Q4 | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Phi-3.5-mini** | 3.8B | ~4GB Q4 | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Gemma-2-2B** | 2B | ~2GB Q4 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Qwen2.5-1.5B** | 1.5B | ~1.5GB Q4 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **TinyLlama-1.1B** | 1.1B | ~1GB Q4 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **SmolLM-360M** | 360M | ~400MB Q4 | ⭐⭐⭐⭐⭐ | ⭐⭐ |

### 🎯 Recomendación: Arquitectura Híbrida "Cerebro Biológico"

```
┌─────────────────────────────────────────────────────────────────┐
│                    BABY LLM ARCHITECTURE                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ┌─────────────────┐    ┌─────────────────┐                   │
│   │  SmolLM-360M    │    │   Phi-3-mini    │                   │
│   │  (Fast Brain)   │◄──►│  (Deep Brain)   │                   │
│   │  Reflexes/Quick │    │  Reasoning/Hard │                   │
│   └────────┬────────┘    └────────┬────────┘                   │
│            │                      │                             │
│            └──────────┬───────────┘                             │
│                       ▼                                         │
│   ┌─────────────────────────────────────────────────────────┐  │
│   │              MEMORY ORCHESTRATOR (Rust)                  │  │
│   │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────────┐   │  │
│   │  │Working  │ │Episodic │ │Semantic │ │Procedural   │   │  │
│   │  │Memory   │ │Memory   │ │Memory   │ │Memory       │   │  │
│   │  │(Buffer) │ │(Events) │ │(Facts)  │ │(Skills)     │   │  │
│   │  └─────────┘ └─────────┘ └─────────┘ └─────────────┘   │  │
│   └─────────────────────────────────────────────────────────┘  │
│                       │                                         │
│                       ▼                                         │
│   ┌─────────────────────────────────────────────────────────┐  │
│   │           isar_agent_memory (ObjectBox + HNSW)           │  │
│   └─────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🧠 Arquitectura de Memoria Biológica

### Inspiración: Sistemas de Memoria Humana

```
                    ┌──────────────────────────────────────┐
                    │         CÓRTEX PREFRONTAL            │
                    │    (Razonamiento/Planificación)      │
                    │         [Phi-3-mini LLM]             │
                    └──────────────────┬───────────────────┘
                                       │
        ┌──────────────────────────────┼──────────────────────────────┐
        │                              │                              │
        ▼                              ▼                              ▼
┌───────────────┐            ┌─────────────────┐            ┌─────────────────┐
│   AMÍGDALA    │            │   HIPOCAMPO     │            │   CEREBELO      │
│  (Emocional)  │            │   (Episódico)   │            │  (Procedural)   │
│               │            │                 │            │                 │
│ - Valence +/- │            │ - Eventos       │            │ - Habilidades   │
│ - Relevancia  │            │ - Contexto      │            │ - Rutinas       │
│ - Priorización│            │ - Tiempo/Lugar  │            │ - Automatismos  │
└───────┬───────┘            └────────┬────────┘            └────────┬────────┘
        │                             │                              │
        └─────────────────────────────┼──────────────────────────────┘
                                      │
                                      ▼
                    ┌─────────────────────────────────────┐
                    │        NEOCÓRTEX (Semántico)        │
                    │     Conocimiento Cristalizado       │
                    │     [Vector Store - ObjectBox]      │
                    └─────────────────────────────────────┘
```

### Tipos de Memoria Implementados

#### 1. Memoria de Trabajo (Working Memory)
```
Duración: Segundos a minutos
Capacidad: ~7±2 items (Miller's Law)
Implementación: Buffer circular en RAM
Función: Contexto inmediato de la conversación
```

#### 2. Memoria Episódica (Autobiográfica)
```
Duración: Días a años
Capacidad: Ilimitada (con decay)
Implementación: ObjectBox + embeddings temporales
Función: "¿Qué pasó?" - Eventos con contexto espacio-temporal
```

#### 3. Memoria Semántica (Hechos/Conocimiento)
```
Duración: Permanente
Capacidad: Ilimitada
Implementación: Vector store + graph relationships
Función: "¿Qué sé?" - Conocimiento general sin contexto temporal
```

#### 4. Memoria Procedural (Habilidades)
```
Duración: Permanente
Capacidad: Limitada por práctica
Implementación: Fine-tuned adapters + cached procedures
Función: "¿Cómo lo hago?" - Automatismos aprendidos
```

---

## 📱 Sistema de Onboarding: "Digestión del Dispositivo"

### Fuentes de Datos Disponibles en Android/iOS

| Fuente | Android API | iOS API | Datos Extraíbles | Privacidad |
|--------|-------------|---------|------------------|------------|
| **Contactos** | ContactsContract | CNContactStore | Nombres, relaciones, frecuencia | 🔒 Permiso |
| **Calendario** | CalendarContract | EventKit | Eventos, patrones, rutinas | 🔒 Permiso |
| **SMS/Mensajes** | Telephony.Sms | Messages (limitado) | Comunicaciones, tono | 🔒🔒 Sensible |
| **Apps instaladas** | PackageManager | (No disponible) | Intereses, categorías | ⚠️ Inferido |
| **Uso de apps** | UsageStatsManager | Screen Time API | Patrones de comportamiento | 🔒 Permiso |
| **Ubicaciones** | FusedLocationProvider | CLLocationManager | Lugares frecuentes, rutinas | 🔒🔒 Sensible |
| **Fotos EXIF** | MediaStore | PHPhotoLibrary | Lugares, fechas, personas | 🔒🔒 Sensible |
| **Notificaciones** | NotificationListenerService | UNUserNotificationCenter | Apps importantes, alertas | 🔒 Permiso |
| **Historial web** | Browser providers | Safari (limitado) | Intereses, búsquedas | 🔒🔒 Sensible |
| **WiFi guardadas** | WifiManager | NEHotspotConfigurationManager | Lugares frecuentes | ⚠️ Inferido |
| **Bluetooth paired** | BluetoothAdapter | CBCentralManager | Dispositivos, contexto | ⚠️ Inferido |
| **Sensores** | SensorManager | CMMotionManager | Actividad física, patrones | 🔒 Continuo |
| **Clipboard** | ClipboardManager | UIPasteboard | Copias recientes | ⚠️ Efímero |
| **Accessibility** | AccessibilityService | (Limitado) | TODO en pantalla | 🔒🔒🔒 Crítico |

### Proceso de Onboarding

```
┌─────────────────────────────────────────────────────────────────────┐
│                     ONBOARDING PIPELINE                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  FASE 1: CONSENT & PERMISSIONS (5 min)                             │
│  ─────────────────────────────────────                             │
│  □ Explicar qué datos se procesarán                                │
│  □ Solicitar permisos granulares                                   │
│  □ Configurar nivel de privacidad                                  │
│                                                                     │
│  FASE 2: SCRAPING PARALELO (Rust) (10-30 min)                      │
│  ──────────────────────────────────────────                        │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐  │
│  │ Thread 1    │ │ Thread 2    │ │ Thread 3    │ │ Thread 4    │  │
│  │ Contactos   │ │ Calendario  │ │ App Usage   │ │ Ubicaciones │  │
│  │ + SMS       │ │ + Eventos   │ │ + Stats     │ │ + WiFi      │  │
│  └──────┬──────┘ └──────┬──────┘ └──────┬──────┘ └──────┬──────┘  │
│         │               │               │               │          │
│         └───────────────┴───────────────┴───────────────┘          │
│                                │                                    │
│                                ▼                                    │
│  FASE 3: PROCESAMIENTO (Parallel Rust Workers)                     │
│  ─────────────────────────────────────────────                     │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ 1. Chunking: Dividir datos en fragmentos procesables        │ │
│  │ 2. Embedding: Generar vectores (on-device ONNX)             │ │
│  │ 3. Classification: Categorizar por tipo de memoria          │ │
│  │ 4. Entity Extraction: Extraer entidades (personas, lugares) │ │
│  │ 5. Relationship Building: Construir grafo de conocimiento   │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                │                                    │
│                                ▼                                    │
│  FASE 4: ALMACENAMIENTO (ObjectBox + isar_agent_memory)           │
│  ───────────────────────────────────────────────────────          │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐      │
│  │ Vector Index    │ │ Memory Graph    │ │ Entity Store    │      │
│  │ (HNSW)          │ │ (Relationships) │ │ (People/Places) │      │
│  └─────────────────┘ └─────────────────┘ └─────────────────┘      │
│                                                                     │
│  FASE 5: PROFILE GENERATION (LLM Summarization)                    │
│  ─────────────────────────────────────────────                     │
│  → Generar "User Profile" inicial                                  │
│  → Identificar patrones de comportamiento                          │
│  → Crear grafo de relaciones sociales                              │
│  → Inferir preferencias y intereses                                │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🦀 Componentes Rust de Alto Rendimiento

### Módulos a Implementar en Rust

```rust
// baby_llm_core/src/lib.rs

/// Módulos de alto rendimiento implementados en Rust
pub mod memory {
    pub mod working_memory;      // Buffer circular lock-free
    pub mod consolidation;       // Sleep-like memory consolidation
    pub mod forgetting;          // Importance decay + cleanup
    pub mod retrieval;           // Parallel HNSW search
}

pub mod scraping {
    pub mod android_bridge;      // JNI bindings para Android
    pub mod ios_bridge;          // FFI bindings para iOS
    pub mod parallel_scraper;    // Rayon-powered parallel extraction
    pub mod data_normalizer;     // Normalización de datos heterogéneos
}

pub mod embeddings {
    pub mod onnx_runtime;        // Inferencia ONNX paralela
    pub mod quantization;        // Dynamic quantization
    pub mod batch_processor;     // Batch embedding generation
}

pub mod learning {
    pub mod online_learning;     // Continual learning algorithms
    pub mod lora_adapter;        // LoRA weight updates
    pub mod curriculum;          // Curriculum learning scheduler
}

pub mod inference {
    pub mod llm_engine;          // LLM inference engine
    pub mod speculative;         // Speculative decoding
    pub mod kv_cache;            // KV-cache management
}
```

### Ejemplo: Memory Consolidation en Rust

```rust
use rayon::prelude::*;
use std::sync::Arc;
use parking_lot::RwLock;

/// Consolidación de memorias similar al sueño REM
pub struct MemoryConsolidator {
    episodic_buffer: Arc<RwLock<Vec<EpisodicMemory>>>,
    semantic_store: Arc<RwLock<SemanticStore>>,
    importance_threshold: f32,
}

impl MemoryConsolidator {
    /// Ejecuta consolidación paralela (simula sueño)
    pub async fn sleep_consolidation(&self) -> ConsolidationReport {
        let buffer = self.episodic_buffer.read();

        // Fase 1: Replay paralelo de memorias importantes
        let important_memories: Vec<_> = buffer
            .par_iter()
            .filter(|m| m.importance > self.importance_threshold)
            .cloned()
            .collect();

        // Fase 2: Clustering por similitud semántica
        let clusters = self.cluster_memories(&important_memories);

        // Fase 3: Generar abstracciones (episódico → semántico)
        let abstractions: Vec<SemanticFact> = clusters
            .par_iter()
            .map(|cluster| self.abstract_cluster(cluster))
            .collect();

        // Fase 4: Integrar en memoria semántica
        let mut semantic = self.semantic_store.write();
        for fact in abstractions {
            semantic.integrate(fact);
        }

        // Fase 5: Decay de memorias episódicas procesadas
        drop(buffer);
        let mut buffer = self.episodic_buffer.write();
        buffer.retain(|m| m.importance > self.importance_threshold * 0.5);

        ConsolidationReport {
            memories_processed: important_memories.len(),
            facts_extracted: abstractions.len(),
            memories_forgotten: buffer.len(),
        }
    }
}
```

### Ejemplo: Parallel Scraping

```rust
use tokio::task::JoinSet;
use rayon::prelude::*;

pub struct DeviceScraper {
    permissions: PermissionSet,
}

impl DeviceScraper {
    /// Scraping paralelo de todas las fuentes disponibles
    pub async fn full_device_scan(&self) -> DeviceProfile {
        let mut tasks = JoinSet::new();

        // Spawn tareas paralelas para cada fuente
        if self.permissions.contacts {
            tasks.spawn(async { scrape_contacts().await });
        }
        if self.permissions.calendar {
            tasks.spawn(async { scrape_calendar().await });
        }
        if self.permissions.usage_stats {
            tasks.spawn(async { scrape_app_usage().await });
        }
        if self.permissions.location {
            tasks.spawn(async { scrape_location_history().await });
        }
        if self.permissions.notifications {
            tasks.spawn(async { scrape_notification_patterns().await });
        }

        // Recolectar resultados
        let mut profile = DeviceProfile::new();
        while let Some(result) = tasks.join_next().await {
            match result {
                Ok(data) => profile.merge(data),
                Err(e) => log::warn!("Scraping task failed: {}", e),
            }
        }

        // Procesamiento paralelo de los datos recolectados
        profile.chunks = profile.raw_data
            .par_chunks(1000)
            .map(|chunk| process_chunk(chunk))
            .collect();

        profile
    }
}
```

---

## 🔄 Sistema de Aprendizaje Continuo

### Inspiración: Neuroplasticidad

```
┌─────────────────────────────────────────────────────────────────────┐
│                    NEUROPLASTICITY SIMULATION                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  1. HEBBIAN LEARNING: "Neurons that fire together wire together"   │
│  ────────────────────────────────────────────────────────────────  │
│  → Memorias accedidas juntas fortalecen sus conexiones             │
│  → Implementado via edge weights en el grafo de memoria            │
│                                                                     │
│  2. SYNAPTIC PRUNING: "Use it or lose it"                          │
│  ────────────────────────────────────────                          │
│  → Memorias no accedidas decaen gradualmente                       │
│  → ForgettingMechanism con exponential decay                       │
│                                                                     │
│  3. NEUROGENESIS: Creación de nuevas "neuronas"                    │
│  ─────────────────────────────────────────────                     │
│  → Nuevos nodos de memoria cuando se aprende algo nuevo            │
│  → Nuevas conexiones cuando se descubren relaciones                │
│                                                                     │
│  4. LONG-TERM POTENTIATION (LTP): Fortalecimiento por repetición   │
│  ───────────────────────────────────────────────────────────────   │
│  → Memorias accedidas frecuentemente aumentan importance score     │
│  → Se vuelven más resistentes al olvido                            │
│                                                                     │
│  5. SLEEP CONSOLIDATION: Transferencia episódica → semántica       │
│  ──────────────────────────────────────────────────────────        │
│  → Background process durante idle time                            │
│  → Extrae "hechos" de eventos repetidos                            │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Algoritmo de Aprendizaje Online

```
┌─────────────────────────────────────────────────────────────────────┐
│                    ONLINE LEARNING PIPELINE                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  INPUT: Nueva interacción/observación                              │
│         │                                                           │
│         ▼                                                           │
│  ┌─────────────────┐                                               │
│  │ 1. PERCEPTION   │  Extraer entidades, intenciones, contexto     │
│  │    (SmolLM)     │                                               │
│  └────────┬────────┘                                               │
│           │                                                         │
│           ▼                                                         │
│  ┌─────────────────┐                                               │
│  │ 2. ENCODING     │  Generar embedding, clasificar tipo memoria   │
│  │    (ONNX Rust)  │                                               │
│  └────────┬────────┘                                               │
│           │                                                         │
│           ▼                                                         │
│  ┌─────────────────┐                                               │
│  │ 3. RETRIEVAL    │  Buscar memorias relacionadas (HNSW)          │
│  │    (Rust)       │                                               │
│  └────────┬────────┘                                               │
│           │                                                         │
│           ▼                                                         │
│  ┌─────────────────┐                                               │
│  │ 4. INTEGRATION  │  ¿Nueva info? ¿Actualización? ¿Contradicción? │
│  │    (Phi-3)      │                                               │
│  └────────┬────────┘                                               │
│           │                                                         │
│           ├─── Si nueva ──────► Crear nodo + conexiones            │
│           ├─── Si update ─────► Actualizar nodo existente          │
│           └─── Si conflicto ──► Resolver via LLM + timestamp       │
│                                                                     │
│           ▼                                                         │
│  ┌─────────────────┐                                               │
│  │ 5. REINFORCEMENT│  Actualizar importance de memorias usadas     │
│  │    (Rust)       │                                               │
│  └────────┬────────┘                                               │
│           │                                                         │
│           ▼                                                         │
│  ┌─────────────────┐                                               │
│  │ 6. ADAPTATION   │  Opcional: Fine-tune LoRA si suficiente data  │
│  │    (Background) │                                               │
│  └─────────────────┘                                               │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 📦 Estructura del Proyecto

```
baby_llm/
├── 📁 dart/                          # Flutter app + isar_agent_memory
│   ├── lib/
│   │   ├── main.dart                 # Entry point
│   │   ├── baby_llm.dart             # Main orchestrator
│   │   ├── onboarding/
│   │   │   ├── permission_manager.dart
│   │   │   ├── data_sources.dart
│   │   │   └── onboarding_flow.dart
│   │   ├── inference/
│   │   │   ├── model_manager.dart    # Gestión SmolLM + Phi-3
│   │   │   ├── router.dart           # Decide qué modelo usar
│   │   │   └── response_generator.dart
│   │   └── memory/
│   │       └── (usa isar_agent_memory)
│   └── pubspec.yaml
│
├── 📁 rust/                          # Rust core (baby_llm_core)
│   ├── Cargo.toml
│   ├── src/
│   │   ├── lib.rs
│   │   ├── memory/
│   │   │   ├── mod.rs
│   │   │   ├── working_memory.rs     # Lock-free circular buffer
│   │   │   ├── consolidation.rs      # Sleep-like consolidation
│   │   │   ├── forgetting.rs         # Importance decay
│   │   │   └── retrieval.rs          # Parallel HNSW
│   │   ├── scraping/
│   │   │   ├── mod.rs
│   │   │   ├── android.rs            # JNI bindings
│   │   │   ├── ios.rs                # FFI bindings
│   │   │   └── normalizer.rs
│   │   ├── embeddings/
│   │   │   ├── mod.rs
│   │   │   ├── onnx.rs               # ONNX Runtime
│   │   │   └── batch.rs              # Batch processing
│   │   ├── learning/
│   │   │   ├── mod.rs
│   │   │   ├── online.rs             # Online learning
│   │   │   ├── lora.rs               # LoRA adapter
│   │   │   └── curriculum.rs
│   │   └── inference/
│   │       ├── mod.rs
│   │       ├── engine.rs             # llama.cpp bindings
│   │       ├── kv_cache.rs
│   │       └── speculative.rs
│   └── android/                      # Android NDK build
│       └── build.gradle
│
├── 📁 models/                        # Modelos cuantizados
│   ├── smollm-360m-q4.gguf          # Fast brain (~400MB)
│   ├── phi3-mini-q4.gguf            # Deep brain (~2GB)
│   └── embeddings-mini.onnx         # Embeddings model (~50MB)
│
├── 📁 isar_agent_memory/             # Submodule o local
│   └── ... (tu paquete actual)
│
└── 📁 docs/
    ├── ARCHITECTURE.md
    ├── ONBOARDING.md
    └── PRIVACY.md
```

---

## 🗓️ Roadmap de Desarrollo

### Fase 1: Foundation (4-6 semanas)
```
□ Configurar proyecto Flutter con Rust FFI
□ Integrar llama.cpp para inferencia
□ Implementar carga de SmolLM-360M cuantizado
□ Crear UI básica de chat
□ Integrar isar_agent_memory existente
```

### Fase 2: Onboarding Engine (4-6 semanas)
```
□ Implementar permission manager (Android/iOS)
□ Crear scrapers para cada fuente de datos
□ Implementar parallel scraping en Rust
□ Crear pipeline de procesamiento de datos
□ UI de onboarding con progreso
```

### Fase 3: Memory System (6-8 semanas)
```
□ Implementar Working Memory en Rust (lock-free)
□ Extender isar_agent_memory con nuevos tipos
□ Crear Memory Consolidation engine
□ Implementar Forgetting Mechanism avanzado
□ Crear sistema de importancia dinámica
```

### Fase 4: Learning System (6-8 semanas)
```
□ Implementar online learning pipeline
□ Crear sistema de LoRA adapters
□ Implementar curriculum learning
□ Background consolidation (durante idle)
□ Métricas de aprendizaje
```

### Fase 5: Dual-Brain Architecture (4-6 semanas)
```
□ Integrar Phi-3-mini como segundo modelo
□ Implementar router de queries
□ Speculative decoding (SmolLM draft, Phi-3 verify)
□ Optimizar switching entre modelos
```

### Fase 6: Polish & Optimization (4-6 semanas)
```
□ Optimización de batería
□ Compresión de modelo para dispositivos bajos
□ Testing extensivo
□ Documentación
□ Beta release
```

---

## 💾 Requisitos de Hardware

### Mínimos
```
- RAM: 4GB (6GB recomendado)
- Storage: 5GB disponible
- CPU: ARM64 (Snapdragon 665+ / Apple A11+)
- Android 10+ / iOS 14+
```

### Óptimos
```
- RAM: 8GB+
- Storage: 10GB disponible
- CPU: Snapdragon 8 Gen 1+ / Apple A15+
- GPU: Adreno 730+ / Apple GPU (para aceleración)
```

---

## 🔐 Consideraciones de Privacidad

### Principios Fundamentales

1. **100% On-Device**: Ningún dato sale del dispositivo
2. **Cifrado en Reposo**: Todos los datos cifrados con clave derivada del usuario
3. **Granularidad de Permisos**: Usuario controla cada fuente de datos
4. **Derecho al Olvido**: Botón de "borrar todo" siempre disponible
5. **Transparencia**: Log visible de qué datos se han procesado

### Arquitectura de Privacidad

```
┌─────────────────────────────────────────────────────────────────────┐
│                    PRIVACY ARCHITECTURE                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────────┐     ┌─────────────────┐     ┌──────────────┐  │
│  │  RAW DATA       │────►│  PROCESSING     │────►│  STORAGE     │  │
│  │  (Ephemeral)    │     │  (In-Memory)    │     │  (Encrypted) │  │
│  │                 │     │                 │     │              │  │
│  │  - Nunca toca   │     │  - Solo RAM     │     │  - AES-256   │  │
│  │    disco        │     │  - Vectorizado  │     │  - SQLCipher │  │
│  │  - Auto-delete  │     │  - Anonimizado  │     │  - Key local │  │
│  └─────────────────┘     └─────────────────┘     └──────────────┘  │
│                                                                     │
│  DATOS SENSIBLES:                                                  │
│  ─────────────────                                                 │
│  - PII → Hash + embedding (nunca texto plano)                      │
│  - Contactos → Solo primer nombre + relación inferida              │
│  - Ubicaciones → Solo clusters (no coordenadas exactas)            │
│  - Mensajes → Solo embeddings + sentiment (no contenido)           │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🎯 Conclusión

### ¿Por qué este enfoque?

1. **Práctico**: Usa modelos existentes probados (Phi-3, SmolLM)
2. **Eficiente**: Rust para componentes críticos de rendimiento
3. **Biológico**: Replica sistemas de memoria humana comprobados
4. **Privado**: 100% on-device, sin cloud
5. **Escalable**: Arquitectura modular permite mejoras incrementales

### Próximos Pasos

1. ✅ Documento de arquitectura (este archivo)
2. ⬜ Crear repositorio `baby_llm`
3. ⬜ Configurar proyecto Flutter + Rust FFI
4. ⬜ Integrar primer modelo (SmolLM-360M)
5. ⬜ Implementar onboarding básico

---

## 📚 Referencias

- [Phi-3 Technical Report](https://arxiv.org/abs/2404.14219)
- [SmolLM by HuggingFace](https://huggingface.co/HuggingFaceTB/SmolLM-360M)
- [Memory Systems in the Brain](https://www.ncbi.nlm.nih.gov/books/NBK482171/)
- [Continual Learning in Neural Networks](https://arxiv.org/abs/1802.07569)
- [LoRA: Low-Rank Adaptation](https://arxiv.org/abs/2106.09685)
- Papers descargados en `/research_papers/`
