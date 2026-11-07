# Bug 3: Returning a Value Without Helping Advance the Tail

## 1. Overview

**Component:** `Msqueue.pop`

**File:** `src/msqueue.ml`

**Testing tool:** QCheck-Lin

**Defect:** When `head == tail` but `head.next` contains a node, the implementation returns that node's value instead of helping advance the tail and retrying.

## 2. Original Correct Implementation

```ocaml
if head == tail then
  match next with
  | None -> None
  | Some next_node ->
      let _ = Atomic.compare_and_set q.tail tail next_node in
      loop ()
```

When the head and tail point to the same node but a successor exists, the tail is lagging behind.

The consumer must help advance the tail and retry the operation.

## 3. Injected Fault

We replaced the helping operation with:

```ocaml
if head == tail then
  match next with
  | None -> None
  | Some next_node ->
      next_node.value
```

This returns the value without advancing the queue's head or helping the tail.

## 4. Testing Configuration

- Queue implementation: OCaml 5 Michael–Scott queue
- Testing framework: QCheck-Lin
- Test module: `test/linearizability_test.ml`
- Sequential specification: FIFO queue
- Property tested: Concurrent operation histories must be compatible with a valid sequential execution.

## 5. Counterexample

QCheck-Lin detected the defect after 79 shrinking steps.

**Random seed:** `212813249`

```text
                        |
                        |
             .---------------------.
             |                     |
           pop t                push t 0
                                 pop t
```

Observed results:

```text
pop t : Some (0)
push t 0 : ()
pop t : Some (0)
```

QCheck-Lin reported:

```text
Results incompatible with sequential execution
```

## 6. Why the Bug Occurs

The consumer encounters a state where `head == tail`, but `head.next` is not empty.

This means a producer has linked a new node but has not yet advanced the tail.

The correct algorithm helps advance the tail and retries.

The faulty implementation returns the successor's value immediately, without changing the queue's head.

As a result, another consumer can observe and return the same value. The resulting history cannot be explained by a valid sequential FIFO queue.

## 7. Corrected Implementation

The faulty branch was restored to:

```ocaml
| Some next_node ->
    let _ = Atomic.compare_and_set q.tail tail next_node in
    loop ()
```

The consumer helps advance the tail and retries instead of returning a value prematurely.

## 8. Verification After Restoration

After restoring the correct implementation:

- `dune build` passed.
- `dune exec test/test_msqueue.exe` passed.
- `dune exec test/linearizability_test.exe` passed.

QCheck-Lin reported:

```text
success (ran 1 tests)
```

## 9. Conclusion

This experiment demonstrates why a consumer must help advance a lagging tail when the head and tail point to the same node but a successor exists.

QCheck-Lin detected the defect through a concurrent history incompatible with the sequential FIFO specification.
