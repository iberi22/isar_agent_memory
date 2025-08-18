# Changelog

## 0.2.2 - 2025-08-18

- Documentation: README translated to English and Known Issues updated (Gemini API key requirement; Windows `isar.dll` is handled automatically in tests). No functional code changes.

## 0.2.1 - 2025-08-17

- CI/CD: añade workflow `publish-to-pub-dev.yml` para publicación automática en pub.dev al crear un release (`release: published`) o manualmente (`workflow_dispatch`).
- Credenciales: se documenta y habilita el uso del secret `PUB_CREDENTIALS_JSON` (obtenido con `dart pub login`).
- Mantenimiento: preparación de release menor y validación local con formato/análisis/tests.

## 0.2.0 - 2025-08-17

- Sanitización mayor del proyecto para eliminar DVDB como backend vectorial.
  - Se elimina la dependencia `dvdb` del paquete y su export público.
  - Se deja `vector_index_dvdb.dart` como stub deprecado que lanza `UnsupportedError` para evitar uso accidental.
  - ObjectBox queda como único backend soportado/documentado para ANN (HNSW) on-device.
- Tests sin plugins nativos:
  - Nuevo `InMemoryVectorIndex` para pruebas, sin dependencias nativas.
  - Se removió `isar_flutter_libs` del subproyecto de tests.
  - Se deshabilitó el test de plantilla `widget_test.dart` (no aporta a este paquete y requiere UI).
  - Corrección de similitud en el índice en memoria (cosine/L2/dot) para resultados consistentes.
- Documentación:
  - Limpieza de README/TASKS eliminando referencias a DVDB.
  - Aclarado ObjectBox como backend por defecto.
  - Corrección de lints y estructura de secciones.
- Estado: suite de tests pasando en CI local; lista para publicar versión menor con cambios potencialmente disruptivos (pre-1.0).

## 0.1.2 - 2025-07-10

- Fix: Resolved JavaScript error in Isar generated files by integrating `build_runner`.

## 0.1.1 - 2025-07-10

- Documentation: Added comprehensive dartdoc comments to public APIs.
- Linting: Fixed various linting and formatting issues.
- Publishing: Corrected pub.dev topics for successful publication.

## 0.1.0 - 2025-07-09

- Initial release: Isar agent memory graph with ANN search, explainability, robust tests, and modern CI/CD automation (Coderabbit, Renovate, Dependabot, Jules).
