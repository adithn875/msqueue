
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

let count = ref 0 in
let seen = Array.make 40_000 false in

let rec loop () =
  match Msqueue.pop q with
  | None -> ()
  | Some value ->
      assert (value >= 0 && value < 40_000);
      assert (not seen.(value));
      seen.(value) <- true;
      incr count;
      loop ()
in

loop ();
assert (Msqueue.pop q = None);
Array.iter (fun present -> assert present) seen;
assert (!count = 40_000);
  Printf.printf "All four producers passed! Retrieved %d unique elements.\n" !count