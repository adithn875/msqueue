
# Native OCaml 5 Concurrency Stress Testing

## Overview

Stress testing of the Michael–Scott lock-free queue using native OCaml 5 Domains and Atomic operations.

## 1. Four Producers

- Producers: 4
- Elements per producer: 10,000
- Elements per execution: 40,000
- Repetitions: 10
- Successful executions: 10/10
- Total successful retrievals: 400,000

## 2. Two Producers and Two Consumers

- Producers: 2
- Consumers: 2
- Elements per producer: 10,000
- Elements per execution: 20,000
- Repetitions: 10
- Successful executions: 10/10
- Total successful retrievals: 200,000

## 3. Four Producers and Four Consumers

- Producers: 4
- Consumers: 4
- Elements per producer: 10,000
- Elements per execution: 40,000
- Repetitions: 10
- Successful executions: 10/10
- Total successful retrievals: 400,000

## Verification

The tests check:
- Values remain within the expected range.
- No duplicate values are retrieved.
- Every expected value is retrieved.
- The queue is empty after consumption.

## Overall Results

Total successful element retrievals across all three experiments: 1,000,000.

## Limitations

These experiments provide empirical evidence under the tested workloads. They do not prove correctness for all possible executions or independently establish FIFO linearizability.
