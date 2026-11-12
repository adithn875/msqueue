
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

---

## Additional Experiment: 3 Producers + 3 Consumers

### Configuration

- Algorithm: Source-DPOR
- Queue: Michael–Scott lock-free queue
- Atomic implementation: `Dscheck.TracedAtomic`
- Producers: 3
- Consumers: 3
- Initial queue: Empty

### Exploration Attempt

The 3-producer, 3-consumer experiment was executed using:

```bash
dune exec examples/dscheck_mixed_3x3.exe
```

The experiment ran for approximately **2 hours, 12 minutes and 49 seconds** before being manually interrupted using `Ctrl+C`.

### Observations

- Six worker domains were involved in the execution.
- DSCheck continued exploring concurrent schedules.
- The terminal displayed atomic operations and explored execution sequences.
- No completed exploration summary was obtained.

### Result

**Incomplete — manually interrupted.**

The experiment did not finish, so the total number of explored interleavings and states could not be established.

No stack overflow or queue correctness failure was established by this run.

### Limitations

This experiment does not provide a completed correctness result. The incomplete run is recorded as an exploration-cost observation, not as a successful verification or a correctness failure.
