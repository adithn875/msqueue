
let () =
  let q = Msqueue.create () in
  let n = 10_000 in

  (* Shared result tracking *)
  let seen = Array.make (2 * n) false in
  let lock = Mutex.create () in

  (* Track completed producers *)
  let producers_finished = Atomic.make 0 in

  (* Producer function *)
  let producer start =
    for i = start to start + n - 1 do
      Msqueue.push q i
    done;

    Atomic.incr producers_finished
  in

  (* Spawn two producers *)
  let p1 = Domain.spawn (fun () -> producer 0) in
  let p2 = Domain.spawn (fun () -> producer n) in

  (* Consumer function *)
  let consume () =
    let rec loop () =
      match Msqueue.pop q with
      | Some value ->
          Mutex.lock lock;
          Fun.protect
            ~finally:(fun () -> Mutex.unlock lock)
            (fun () ->
              assert (value >= 0 && value < 2 * n);
              assert (not seen.(value));
              seen.(value) <- true
            );
          loop ()

      | None ->
          if Atomic.get producers_finished = 2 then
            ()
          else
            loop ()
    in
    loop ()
  in

  (* Spawn two consumers *)
  let c1 = Domain.spawn consume in
  let c2 = Domain.spawn consume in

  (* Wait for all domains *)
  Domain.join p1;
  Domain.join p2;
  Domain.join c1;
  Domain.join c2;

  (* Verify all elements were retrieved exactly once *)
  Array.iter (fun present -> assert present) seen;
  assert (Msqueue.pop q = None);

  Printf.printf
    "Mixed stress test passed: %d unique elements retrieved.\n"
    (2 * n)
