module Atomic = Dscheck.TracedAtomic
let () =
  Atomic.trace (fun () ->
let counter = Atomic.make 0 in

let rec increment () =
  let current_value = Atomic.get counter in
  let next_value = current_value+1 in
  if Atomic.compare_and_set counter current_value next_value then
    ()
  else
  increment ()
  in
    Atomic.spawn increment;
    Atomic.spawn increment;
    Atomic.spawn increment;


  Atomic.final (fun () ->
  Atomic.check (fun () -> Atomic.get counter = 3);
  Printf.printf "Final counter: %d\n" (Atomic.get counter)
)
)