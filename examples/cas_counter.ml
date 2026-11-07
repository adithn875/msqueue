let rec increment counter =
  let old_value = Atomic.get counter in
  let new_value = old_value + 1 in
  if Atomic.compare_and_set counter old_value new_value then
    ()
else
increment counter
let () =
let counter = Atomic.make 0 in
let d1 = Domain.spawn (fun () ->
  for i = 1 to 100_000 do
  increment counter
  done)in
let d2 = Domain.spawn (fun ()->
  for i = 1 to 100_000 do
  increment counter
  done )in
  Domain.join d1;
  Domain.join d2;
  Printf.printf "final counter : %d/n "(Atomic.get counter)