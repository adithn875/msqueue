# Bug 2: Incorrect Tail Advancement During Helping

## 1. Overview

**Component:** Simplified Michael–Scott queue model

**File:** `examples/dscheck_tail.ml`

**Testing tool:** DSCheck (`Dscheck.TracedAtomic`)

**Exploration strategy:** DPOR (`~impl:\`Dpor`)

**Defect:** Producer B advances the shared tail to a fixed node instead of the node observed through the current tail's `next` pointer.

## 2. Original Correct Implementation

The correct helping operation advances the tail to the observed next node:

```ocaml
| Some next_node ->
    ignore (Atomic.compare_and_set tail old_tail next_node);
    producer_b ()
```

This allows a producer to help advance a lagging tail using the queue's linked-list structure.

## 3. Injected Fault

We deliberately changed the helping operation in Producer B:

```ocaml
| Some next_node ->
    ignore (Atomic.compare_and_set tail old_tail c);
    producer_b ()
```

The implementation now attempts to advance the tail to `c`, regardless of the node actually observed through `old_tail.next`.

## 4. Testing Configuration

- Model: Simplified two-producer linked queue
- Atomic operations: `Dscheck.TracedAtomic`
- Scheduler: DPOR
- Invariant: The node referenced by `tail` must be reachable from `head`.
- Test executable: `examples/dscheck_tail.ml`

**Scope limitation:** This experiment uses a simplified model. It is not a direct test of the production `src/msqueue.ml` implementation.

## 5. Counterexample

DSCheck reported an assertion violation at run 6.

The recorded execution included interleaved operations from two producers, including reads and compare-and-set operations on the tail and node links.

The final output included:

```text
Found assertion violation at run 6:
```

followed by the explored execution sequence and:

```text
Fatal error: exception File "src/tracedAtomic.ml",
line 621, characters 4-10: Assertion failed
```

## 6. Why the Bug Occurs

The queue is represented as a linked list, and the tail should always point to a node reachable from the head.

When a producer observes that the current tail has a successor, it helps advance the tail to that successor.

The faulty implementation ignores the observed successor and instead attempts to move the tail to the fixed node `c`.

Under a particular interleaving, this can make the tail point to a node that is not reachable from the head.

DSCheck explores different thread interleavings and detects the violation through the reachability invariant.

## 7. Corrected Implementation

The faulty target was replaced with the observed successor:

```ocaml
| Some next_node ->
    ignore (Atomic.compare_and_set tail old_tail next_node);
    producer_b ()
```

## 8. Verification

The corrected model was restored and inspected. Both Producer A and Producer B use `next_node` in their helping operations.

The production queue was also restored and its basic tests and QCheck-Lin test passed.

## 9. Conclusion

This experiment demonstrates how an incorrect tail-helping operation can violate a structural invariant of a concurrent linked queue.

DSCheck exposed the problem by exploring an interleaving that caused the tail-reachability assertion to fail.

The experiment provides a useful demonstration of systematic concurrency testing, while remaining explicitly limited to the simplified model.
