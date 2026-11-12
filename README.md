# Michael–Scott Lock-Free Queue in OCaml 5

A learning-grade implementation of the **Michael–Scott non-blocking FIFO queue**, built from scratch using OCaml 5 atomic operations.

This project explores lock-free programming, compare-and-set (CAS), helping, concurrent domains, linearizability testing, and systematic concurrency testing.

## Project Overview

The Michael–Scott queue is a linked-list-based concurrent FIFO queue. Multiple producers can insert elements, and multiple consumers can remove elements concurrently.

This implementation uses OCaml's `Atomic` module and a dummy-node representation.

The project aims to understand and investigate the engineering challenges behind lock-free data structures.

## Features

- Michael–Scott lock-free FIFO queue.
- Implemented using OCaml 5 atomic references.
- Functor-based atomic abstraction.
- Compare-and-set operations for concurrent updates.
- Tail helping when another domain leaves the tail pointer behind.
- Unit and native concurrency stress tests.
- QCheck-Lin linearizability testing.
- DSCheck systematic concurrency exploration.
- Three documented bug investigations.
- Native benchmark experiments.

## Architecture

The implementation is organized around three main components.

### 1. Atomic Abstraction

The `ATOMIC` module signature defines the operations required by the queue:

- `make`
- `get`
- `compare_and_set`
- `set`

### 2. Queue Functor

`Make (A : ATOMIC)` constructs a queue using the supplied atomic implementation.

This allows the same queue algorithm to work with OCaml's standard atomic operations or DSCheck's traced atomic operations.

### 3. Default Implementation

`Default` uses OCaml's standard `Atomic` module.

The normal public API provides:

- `create` — create an empty queue.
- `push` — insert an element.
- `pop` — remove the next element, returning `None` if the queue is empty.

## Repository Structure

```text
msqueue/
├── src/
│   ├── msqueue.ml
│   ├── msqueue.mli
│   └── dune
├── test/
│   ├── test_msqueue.ml
│   ├── linearizability_test.ml
│   ├── mixed_stress_test.ml
│   ├── stress_4x4.ml
│   ├── bug2_test.ml
│   └── dune
├── examples/
│   ├── dscheck_msqueue.ml
│   ├── dscheck_mixed.ml
│   ├── dscheck_mixed_3x3.ml
│   ├── dscheck_consumers.ml
│   ├── dscheck_tail.ml
│   ├── dscheck_counter.ml
│   ├── cas_counter.ml
│   ├── cas.ml
│   ├── atomic_counter.ml
│   ├── unsafe_counter.ml
│   ├── domain_demo.ml
│   └── dune
├── bench/
│   ├── bench_queue.ml
│   └── dune
├── docs/
│   ├── benchmarking/
│   ├── bug-investigation/
│   ├── testing/
│   └── dscheck-counter-experiment.md
├── .github/
│   └── workflows/
│       └── ci.yml
├── dune-project
└── README.md
```

## Requirements

- OCaml 5
- Dune 3.24 or compatible
- opam package manager

DSCheck and QCheck-Lin are required for the concurrency testing tools.

### Tested Environment

The project was developed and tested with:

- OCaml 5.2.0
- Dune 3.24
- DSCheck 0.6.0
- QCheck-Lin 0.10
- macOS Tahoe on Apple M5 with 16 GB RAM

The project uses OCaml 5 domains for native concurrency experiments.

## Installation

Install the required packages using opam:

```bash
opam install dune.3.24.0 dscheck.0.6.0 qcheck-lin.0.10
```

Make sure your active opam switch uses OCaml 5.

## Build

Clone the repository:

```bash
git clone https://github.com/adithn875/msqueue.git
cd msqueue
```

Build the project:

```bash
dune build
```

## Basic Usage

The following example demonstrates the queue API in the OCaml toplevel:

```ocaml
let q = Msqueue.create ();;

Msqueue.push q 10;;
Msqueue.push q 20;;
Msqueue.push q 30;;

let first = Msqueue.pop q;;
(* Some 10 *)

let second = Msqueue.pop q;;
(* Some 20 *)

let third = Msqueue.pop q;;
(* Some 30 *)

let empty = Msqueue.pop q;;
(* None *)
```

## Testing

Run the complete test suite:

```bash
dune runtest --force
```

The test suite covers:

- Empty queue behavior.
- FIFO ordering.
- Mixed push and pop operations.
- Reusing the queue after it becomes empty.
- Sequential operations with 10,000 elements.
- Concurrent producers.
- Concurrent consumers.
- Mixed producer-consumer workloads.
- Four producers and four consumers.

### Linearizability Testing

The project uses QCheck-Lin to generate concurrent operation histories and check them against the sequential queue specification.

Run:

```bash
dune exec test/linearizability_test.exe
```

### Native Stress Testing

The native stress experiments include:

| Configuration | Elements |
|---|---:|
| 4 producers | 40,000 |
| 2 producers + 2 consumers | 20,000 |
| 4 producers + 4 consumers | 40,000 |

Each configuration passed 10 repeated runs in the documented experiments.

These tests check element completeness, uniqueness, and successful retrieval. They are stress tests, not exhaustive proofs of correctness.

See [Native Stress Test Results](docs/testing/native-stress-results.md) for details.

### DSCheck Exploration

DSCheck is used to explore possible concurrent interleavings using traced atomic operations.

The 2-producer, 2-consumer experiment completed with:

- 11,198 interleavings.
- 148,161 explored states.
- No assertion failures reported.

The 3-producer, 3-consumer experiment was attempted but manually interrupted after approximately 2 hours, 12 minutes and 49 seconds.

It did not produce a completed exploration result. The run is recorded as incomplete, not as a correctness failure or successful verification.

See [DSCheck Exploration](docs/testing/dscheck-exploration.md) for details.

## Benchmark Results

The native benchmark uses 40,000 pushes and 40,000 pops in each configuration.

Median throughput from 10 measurements:

| Configuration | Median throughput |
|---|---:|
| Sequential | 16,934,504 operations/sec |
| 1 producer + 1 consumer | 15,181,411 operations/sec |
| 2 producers + 2 consumers | 11,553,464 operations/sec |
| 4 producers + 4 consumers | 5,594,486 operations/sec |

These are machine-specific experimental results, not universal performance claims.

See [Native Benchmark Results](docs/benchmarking/native-benchmark-results.md) for methodology, environment, and limitations.

Run the benchmark:

```bash
dune exec bench/bench_queue.exe
```

## Bug Investigations

Three deliberate bug investigations were documented:

1. Failed CAS handling.
2. Incorrect tail helping.
3. Pop without helping.

See `docs/bug-investigation/` for the investigation notes.

## Continuous Integration

GitHub Actions is configured to run the following checks on pushes to `main` and pull requests targeting `main`:

- Set up OCaml 5.2.
- Install project dependencies.
- Build the project.
- Run the complete test suite.

Workflow configuration: `.github/workflows/ci.yml`.

## Limitations

- This is a learning-grade implementation, not a formally verified production library.
- The 3×3 DSCheck exploration remains incomplete.
- Native stress tests do not prove correctness for every possible interleaving.
- QCheck-Lin checks generated histories; it does not exhaustively explore every possible execution.
- Benchmark results depend on the hardware, runtime, and workload.
- `tail_reachable` is a diagnostic helper. Its result is not a guaranteed consistent snapshot during concurrent modification.

## Learning Objectives

This project was built to investigate:

- Lock-free data structures.
- Compare-and-set and atomic references.
- OCaml 5 domains.
- The Michael–Scott queue algorithm.
- Linearization points.
- Helping and lock-free progress.
- Systematic concurrency testing.
- Benchmarking concurrent algorithms.

## References

- Michael, M. M., and Scott, M. L. (1996). *Simple, Fast, and Practical Non-Blocking and Blocking Concurrent Queue Algorithms.*
- [OCaml Documentation](https://ocaml.org/docs)
- [DSCheck](https://github.com/ocaml-multicore/dscheck)
- [QCheck](https://github.com/c-cube/qcheck)

## Author

**Adith N K**

GitHub: [@adithn875](https://github.com/adithn875)

Repository: [msqueue](https://github.com/adithn875/msqueue)
