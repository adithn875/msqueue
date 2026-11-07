let () =
let counter = Atomic.make 0 in
let d1 = Domain.spawn (fun () ->
  for i = 1 to 100_000
   do
  let old_value = Atomic.get counter in
  Atomic.set counter (old_value+1)
  done) in
let d2 = Domain.spawn (fun ()->
  for i = 1 to 100_000
  do
  let old_value = Atomic.get counter in
  Atomic.set counter (old_value +1)
done ) in
Domain.join d1;
Domain.join d2;
Printf.printf "final counter : %d\n"(Atomic.get counter )