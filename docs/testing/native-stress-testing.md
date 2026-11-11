
# Native OCaml 5 Concurrency Stress Testing

## Environment

- Implementation: Michael–Scott lock-free queue
- Runtime: OCaml 5
- Concurrency: Native OCaml domains

## Test configurations

### 1. Four producers

- Producers: 4
- Elements per producer: 10,000
- Total elements: 40,000
- Repetitions: 10
- Result: 10/10 successful

### 2. Two producers and two consumers

- Producers: 2
- Consumers: 2
- Elements per producer: 10,000
- Total elements: 20,000
- Repetitions: 10
- Result: 10/10 successful

### 3. Four producers and four consumers

- Producers: 4
- Consumers: 4
- Elements per producer: 10,000
- Total elements: 40,000
- Repetitions: 10
- Result: 10/10 successful

## Verification properties

- No duplicate values detected.
- No missing values detected.
- No out-of-range values detected.
- Queue empty after consumption.
- All spawned domains completed successfully.

## Limitations

These tests provide empirical evidence under the tested workloads.
They do not prove correctness for all possible concurrent executions
or independently establish FIFO linearizability.
