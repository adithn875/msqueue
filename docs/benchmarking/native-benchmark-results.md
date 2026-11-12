# Native Benchmark Results — MSQueue

**Project:** Michael–Scott Lock-Free Queue in OCaml 5  
**Date:** 12 November 2026  
**Status:** Initial native benchmark report

## 1. Objective

Measure the throughput of the MSQueue implementation under sequential and concurrent workloads using different producer/consumer configurations.

The purpose is to understand how the implementation behaves as the number of concurrent producers and consumers increases.

## 2. Hardware and software environment

| Component | Configuration |
|---|---|
| Machine | MacBook Air, 13-inch |
| Processor | Apple M5 |
| Memory | 16 GB |
| Operating system | macOS Tahoe 26.6.2 |
| OCaml | 5.2.0 |
| Dune language | 3.24 |
| Benchmark implementation | Native OCaml with OCaml 5 domains |
| Timer | `Unix.gettimeofday` |

No deliberate heavy background workload was running during the experiments. Background system activity was not independently monitored.

## 3. Benchmark methodology

Every configuration processes the same total workload:

- 40,000 push operations.
- 40,000 pop operations.
- 80,000 operations per measured run.

| Configuration | Producers | Consumers | Pushes | Pops |
|---|---:|---:|---:|---:|
| Sequential | 1 | 1 | 40,000 | 40,000 |
| 1P + 1C | 1 | 1 | 40,000 | 40,000 |
| 2P + 2C | 2 | 2 | 40,000 | 40,000 |
| 4P + 4C | 4 | 4 | 40,000 | 40,000 |

Each configuration uses:
- One warm-up run, excluded from the reported measurements.
- Ten measured runs.
- A fresh queue for every run.
- Median throughput as the reported result.

Throughput is calculated as:

`Total operations / elapsed time`

Each successful push and pop counts as one operation.

## 4. Results

| Configuration | Median throughput |
|---|---:|
| Sequential | 16,934,504 operations/second |
| 1P + 1C | 15,181,411 operations/second |
| 2P + 2C | 11,553,464 operations/second |
| 4P + 4C | 5,594,486 operations/second |

### Relative throughput

The sequential result is used as the baseline.

| Configuration | Relative throughput |
|---|---:|
| Sequential | 100% |
| 1P + 1C | 89.7% |
| 2P + 2C | 68.2% |
| 4P + 4C | 33.0% |

## 5. Correctness checks

All three concurrent configurations passed the benchmark's result verification.

The verification checks that:
- Every expected value was received.
- No expected value is missing.
- No duplicate value was received.
- No unexpected value was received.

These checks establish value completeness and uniqueness for the tested runs. They do not independently establish concurrent FIFO ordering or linearizability.

## 6. Observations

Throughput decreased as the number of concurrent producers and consumers increased.

Possible contributors include:
- Contention on shared atomic references.
- Failed compare-and-set attempts and retries.
- Cache-coherence traffic between domains.
- Domain scheduling and creation overhead.

These are possible explanations, not experimentally isolated causes.

The measurements do not establish that increasing the number of domains will improve throughput.

## 7. Limitations

1. The sequential benchmark does not create domains, while concurrent benchmarks include domain creation and joining in their timed intervals.
2. Concurrent consumers allocate and collect result lists during the timed workload. The sequential benchmark does not use the same result-collection method.
3. Timing uses `Unix.gettimeofday`, a wall-clock timer.
4. The benchmark does not independently verify FIFO ordering across concurrent operations.
5. Results are specific to the machine, compiler, runtime and operating conditions.
6. The results have not yet been compared with Saturn using an identical benchmark harness.
7. Background system activity was not independently measured.

Therefore, these results are an initial native performance profile, not a definitive comparison with other queue implementations.

## 8. Conclusion

The MSQueue implementation completed all four benchmark configurations. All concurrent value-completeness and uniqueness checks passed.

The measurements show decreasing throughput as concurrency increases in the tested workloads. Further investigation is needed to identify the causes of contention and to make the benchmark harness more comparable across configurations.

These performance results should be considered alongside the project's separate unit, stress, linearizability and model-checking tests.