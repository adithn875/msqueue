
let () =
  let q = Msqueue.create () in

  (* Each producer pushes 10,000 elements *)
  let producer start =
    for i = start to start + 9_999 do
      Msqueue.push q i
    done
  in

  (* Start four concurrent producers *)
  let producers =
    List.init 4 (fun i ->
      Domain.spawn (fun () -> producer (i * 10_000)))
  in

  (* Wait for all producers *)
  List.iter Domain.join producers;

  Printf.printf "All four producers finished\n";

  (* Consume all elements *)
  let count = ref 0 in
  while Msqueue.pop q <> None do
    incr count
  done;

  Printf.printf "Elements retrieved: %d\n" !count
