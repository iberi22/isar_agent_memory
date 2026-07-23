# Benchmark Report

**Date:** 2026-07-23 03:55:43.131156Z
**Device:** linux (4 cores)
**Model:** all-MiniLM-L6-v2 (INT8)
**Backend:** ONNX Runtime
**Total Samples:** 120

## Latency (ms)

| Metric | Value |
|--------|-------|
| Avg    | 7.68 |
| Min    | 4.50 |
| **p50**| **6.42** |
| p90    | 11.58 |
| **p95**| **15.22** |
| p99    | 18.59 |
| Max    | 44.56 |

## Throughput

- **Est. IPS (Inferences Per Second):** 130.2

## Retrieval Quality Metrics (Cosine Similarity)

| Category | Precision@1 | Recall@1 | Precision@3 | Recall@3 | Precision@5 | Recall@5 |
|----------|-------------|----------|-------------|----------|-------------|----------|
| **Overall** | 100.0% | 100.0% | 33.3% | 100.0% | 20.0% | 100.0% |
| UI | 100.0% | 100.0% | 33.3% | 100.0% | 20.0% | 100.0% |
| architecture | 100.0% | 100.0% | 33.3% | 100.0% | 20.0% | 100.0% |
| code | 100.0% | 100.0% | 33.3% | 100.0% | 20.0% | 100.0% |
| temporal | 100.0% | 100.0% | 33.3% | 100.0% | 20.0% | 100.0% |
