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