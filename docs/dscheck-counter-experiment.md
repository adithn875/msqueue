# Experiment 01: Detecting Lost Updates with DSCheck

**Project:** msqueue  
**Experiment:** Concurrent Counter  
**Tool:** DSCheck 0.6.0  
**Language:** OCaml 5.2.0  
**Status:** Completed

## 1. Objective

Understand how concurrent processes accessing shared mutable state can cause lost updates.

The goal was to implement a shared counter, spawn three concurrent processes, and investigate whether all increments are preserved.

## 2. Initial Implementation

```ocaml
module Atomic = Dscheck.TracedAtomic

let () =
  Atomic.trace (fun () ->
    let counter = Atomic.make 0 in

    let increment () =
      let current = Atomic.get counter in
      Atomic.set counter (current + 1)
    in

    Atomic.spawn increment;
    Atomic.spawn increment;
    Atomic.spawn increment;

    Atomic.final (fun () ->
      Printf.printf "Final counter: %d\n" (Atomic.get counter)
    )
  )
```

## 3. Expected Behaviour

- Initial counter = 0
- Number of processes = 3
- Each process increments the counter once.
- Expected final counter = 3.

## 4. Observed Results

DSCheck explored different execution schedules and produced these final values:

| Final counter | Interpretation |
|---|---|
| 1 | Two updates lost |
| 2 | One update lost |
| 3 | All updates preserved |

## 5. Root Cause

The increment operation uses two separate atomic operations:

```ocaml
let current = Atomic.get counter in
Atomic.set counter (current + 1)
```

Although each operation is individually atomic, the entire read-modify-write sequence is not atomic.

Multiple processes can read the same old value and overwrite each other's updates.

This problem is known as a **lost-update bug**.

## 6. What I Learned

1. How to use `Dscheck.TracedAtomic`.
2. How to create simulated concurrent processes using `Atomic.spawn`.
3. How DSCheck explores execution schedules.
4. How to use `Atomic.final` and `Atomic.check`.
5. Why individual atomic operations do not guarantee correctness of a complete operation.
6. How concurrency bugs can be exposed through schedule exploration.

## 7. Next Experiment

Implement a Compare-and-Set (CAS) based increment operation.

The objective is to prevent an update from overwriting a value that another process has already changed.

**Conclusion:** DSCheck successfully exposed lost updates in a deliberately incorrect concurrent counter implementation.