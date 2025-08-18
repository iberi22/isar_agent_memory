---
Descripción: Plan de implementación y mejoras prioritarias
---

# Sprint actual: Adapter de Embeddings 100% On-Device (Prioridad Máxima)

Estado general: on-device first. Cloud (Gemini) solo como fallback.

## Objetivos del sprint

- Implementar `OnDeviceEmbeddingsAdapter` (TFLite u ONNX Runtime) con modelo compacto (256–384 dims) y soporte INT8.
- Investigar y documentar: consumo de memoria, tiempos de inferencia, compatibilidad por dispositivo/ABI, y sincronización multi-app.
- Mantener ObjectBox Vector Search (HNSW) como backend ANN y validar desempeño end-to-end.

## Tareas técnicas

1. Selección de backend on-device
   - Evaluar `tflite_flutter` vs `onnxruntime` (disponibilidad, tamaño, EPs: NNAPI, CPU, GPU).
   - Elegir modelo base (p. ej. MiniLM/E5-small) y preparar export (ONNX/TFLite) + quantización INT8.

2. Adapter y utilidades
   - Crear `OnDeviceEmbeddingsAdapter` con inicialización perezosa y batch embedding.
   - Manejar versiones/dimensiones por `namespace` y normalización L2 opcional.
   - Telemetría: latencias p50/p95, memoria pico, errores.

3. Investigación de recursos (documentar en README)
   - Tamaño del modelo (fp32 vs INT8) y RAM requerida en inferencia (modelo + buffers).
   - Coste de almacenamiento por N vectores (fp32 vs INT8) y sobrecarga HNSW aproximada.
   - Límites por dispositivo/ABI (armeabi-v7a, arm64-v8a) y políticas de split-ABI.

4. Sincronización multi-app (diseño)
   - Encriptación cliente (clave por usuario), versionado, reconciliación (LWW/CRDT) y deduplicación semántica.
   - Sincronización de embeddings y metadatos en background con cuotas/umbrales.

5. Benchmarks y calidad
   - Microbenchmarks de embed/search (latencia y throughput) y accuracy sanity (semantic pairs).
   - Tests de estrés y concurrencia (ingesta + búsqueda simultánea).

6. Híbrido y re-rank (fase 2)
   - Añadir BM25/FTS (SQLite) para recall y fusión MMR.
   - Re-ranker compacto on-device sobre top-K.

## Entregables

- Adapter on-device funcional + ejemplo de uso.
- Guía de recursos y límites, tabla comparativa TFLite vs ONNX.
- Benchmarks reproducibles y reporte.
- Diseño de sincronización y plan de implementación.

## Notas de investigación inicial

- Memoria del modelo:
  - MiniLM/E5-small fp32: ~60–90 MB; INT8: ~15–25 MB.
  - `onnxruntime` AAR: ~7–12 MB (según EPs); `tflite_flutter`: ~2–3 MB.
- RAM en inferencia:
  - Pico ≈ tamaño modelo + buffers intermedios (1.2–2.0× del modelo) por batch.
  - Recomendado batch pequeño (1–8) en gama media; medir p50/p95.
- Almacenamiento del índice:
  - Vectores: N × d × bytes (fp32: 4B, int8: 1B). Ej.: 50k × 384 × 4 ≈ 76.8 MB; int8 ≈ 19.2 MB.
  - HNSW overhead aproximado: ~N × M × 8B (M≈16 por defecto → ~6.4 MB para 50k).
- Compatibilidad/ABIs:
  - Android: arm64-v8a (recomendado), armeabi-v7a (limitado). Usar split-ABI para reducir tamaño.
  - Aceleradores: NNAPI (variabilidad por OEM), CPU fallback universal.
- Sincronización (multi-app):
  - Cifrado cliente (clave por usuario), versionado LWW/CRDT, deduplicación semántica.
  - Subir sólo metadatos + embeddings (posible int8) con cuotas y sync incremental.
  - Opcional: ObjectBox Sync si se requiere near-real-time y conflicto mínimo.

---

## Publicación 0.2.1 (pendiente)

- [ ] Limpiar binarios/artefactos del repo (dejar de trackear): `.dart_tool/`, `isar.dll`, `example/isar.dll`, `*db/`, `isar_agent_memory_tests/testdb/`.
- [ ] Confirmar `pubspec.yaml` versión `0.2.1` y `CHANGELOG.md` actualizado.
- [ ] Ejecutar workflow manual `.github/workflows/publish-to-pub-dev.yml` en `main`.
- [ ] Verificar publicación en pub.dev (`isar_agent_memory 0.2.1`).
- [ ] Crear tag/release si faltara (`v0.2.1`).

---

## Tareas completadas (resumen)

- [x] Backend vectorial pluggable (`VectorIndex`) y `ObjectBoxVectorIndex` por defecto.
- [x] Fallback de embeddings (Gemini) y `FallbackEmbeddingsAdapter`.
- [x] InMemoryVectorIndex para tests (sin nativos), métrica coseno/L2/dot.
- [x] Sanitización DVDB (código, docs, tests) y README/TASKS actualizados.
- [x] Bump versión 0.2.0, `flat_buffers` y `.pubignore` reforzada.
