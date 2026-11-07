# Bug 1: Returning a Value After a Failed Compare-and-Set

## 1. Overview

**Component:** `Msqueue.pop`

**Defect:** The implementation returns the dequeued value even when the compare-and-set (CAS) operation on the queue's head fails.

**Testing tool:** QCheck-Lin

**Expected behaviour:** If the CAS operation fails, the consumer must retry the operation using the latest queue state.

## 2. Original Correct Implementation

The original implementation checks whether it successfully advances the queue's head.

```ocaml
if Atomic.compare_and_set q.head head next_node then
  value
else
  loop ()
```

A successful CAS advances the head and allows the consumer to return the value. A failed CAS means another concurrent operation changed the head, so the consumer retries.

## 3. Injected Fault

We deliberately replaced the retry branch with a value return:

```ocaml
if Atomic.compare_and_set q.head head next_node then
  value
else
  value
```

This allows a consumer to return a value even though it did not successfully advance the head.

## 4. Testing Configuration

- Testing framework: QCheck-Lin
- Queue implementation: OCaml 5 Michael–Scott queue
- Test module: `test/linearizability_test.ml`
- Sequential specification: FIFO queue
- Property tested: Concurrent operation histories must be compatible with a valid sequential execution.

## 5. Counterexample

QCheck-Lin detected the defect and produced the following counterexample after 79 shrinking steps:

```text
             push t 0
                |
       .---------------------.
       |                     |
     pop t                 pop t
```

Observed results:

```text
push t 0 : ()
pop t : Some (0)
pop t : Some (0)
```

QCheck-Lin reported:

```text
Results incompatible with sequential execution
```

## 6. Why the Bug Occurs

Only one element, `0`, was inserted into the queue.

Two concurrent consumers both returned `Some 0`.

The first consumer successfully removed the element. The second consumer should have detected that its CAS operation failed and retried.

Instead, the faulty implementation returned the same value without successfully advancing the head.

This violates the FIFO queue's sequential specification because a single inserted element cannot be removed twice.

## 7. Corrected Implementation

The faulty branch was restored to:

```ocaml
if Atomic.compare_and_set q.head head next_node then
  value
else
  loop ()
```

The retry is essential because a failed CAS indicates that the observed queue state is no longer current.

## 8. Verification After Restoration

After restoring the correct implementation, the following checks passed:

- `dune build`
- `dune exec test/test_msqueue.exe`
- `dune exec test/linearizability_test.exe`

QCheck-Lin reported:

```text
success (ran 1 tests)
```

## 9. Conclusion

This experiment demonstrates how an incorrect CAS failure branch can cause duplicate dequeue results under concurrency.

QCheck-Lin detected the defect by generating a concurrent history that could not be explained by any valid sequential FIFO execution.

It also demonstrates why a failed CAS must trigger a retry rather than returning a result based on a stale observation.
