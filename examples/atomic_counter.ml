let () =
  let counter = Atomic.make 0 in

  let d1 = Domain.spawn (fun () ->
    for i = 1 to 100_000 do
     ignore (Atomic.fetch_and_add counter 1)
    done
  ) in

  let d2 = Domain.spawn (fun () ->
    for i = 1 to 100_000 do
      ignore (Atomic.fetch_and_add counter 1)
    done
  ) in

  Domain.join d1;
  Domain.join d2;

  Printf.printf "Final counter: %d\n" (Atomic.get counter)