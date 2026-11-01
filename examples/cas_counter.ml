module Atomic = Dscheck.TracedAtomic

let () =
  Atomic.trace (fun () ->
    let counter = Atomic.make 0 in

    let increment () =
      let finished = ref false in

      while not !finished do
        let current = Atomic.get counter in

        if Atomic.compare_and_set counter current (current + 1) then
          finished := true
      done
    in

    Atomic.spawn increment;
    Atomic.spawn increment;
    Atomic.spawn increment;

    Atomic.final (fun () ->
      Printf.printf "Final counter: %d\n" (Atomic.get counter);
      Atomic.check (fun () -> Atomic.get counter = 3)
    )
  )