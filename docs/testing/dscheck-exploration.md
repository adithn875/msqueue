
# DSCheck Exploration: Mixed Producer-Consumer Test

## Configuration

- Algorithm: Source-DPOR
- Queue: Michael-Scott lock-free queue
- Atomic implementation: Dscheck.TracedAtomic
- Producers: 2
- Consumers: 2
- Initial queue: Empty

## Operations

- Producer 1 pushes 10.
- Producer 2 pushes 20.
- Consumer 1 performs one pop.
- Consumer 2 performs one pop.

## Assertions

- Consumer results are valid.
- No value is consumed twice.
- Both pushed values are accounted for exactly once.
- No unexpected values remain in the queue.

## Exploration Results

- Explored interleavings: 11,198
- Explored states: 148,161
- Assertion failures: None reported.

## Limitations

This experiment checks the stated invariants for the explored
execution schedules. It does not independently establish
complete FIFO linearizability or prove the queue correct
for all possible executions.
