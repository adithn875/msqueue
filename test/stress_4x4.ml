
let () =
  let q = Msqueue.create () in
  let n = 10_000 in

  (* Shared result tracking *)
  let seen = Array.make (4 * n) false in
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

  (* Consumer function *)
  let consume () =
    let rec loop () =
      match Msqueue.pop q with
      | Some value ->
          Mutex.lock lock;
          Fun.protect
            ~finally:(fun () -> Mutex.unlock lock)
            (fun () ->
              assert (value >= 0 && value < 4 * n);
              assert (not seen.(value));
              seen.(value) <- true
            );
          loop ()

      | None ->
          if Atomic.get producers_finished = 4 then
            ()
          else
            loop ()
    in
    loop ()
  in

  (* Start four producers *)
  let p1 = Domain.spawn (fun () -> producer 0) in
  let p2 = Domain.spawn (fun () -> producer n) in
  let p3 = Domain.spawn (fun () -> producer (2 * n)) in
  let p4 = Domain.spawn (fun () -> producer (3 * n)) in

  (* Start four consumers while producers are running *)
  let c1 = Domain.spawn consume in
  let c2 = Domain.spawn consume in
  let c3 = Domain.spawn consume in
  let c4 = Domain.spawn consume in

  (* Wait for all producers *)
  Domain.join p1;
  Domain.join p2;
  Domain.join p3;
  Domain.join p4;

  (* Wait for all consumers *)
  Domain.join c1;
  Domain.join c2;
  Domain.join c3;
  Domain.join c4;

  (* Verify every element was retrieved exactly once *)
  Array.iter (fun present -> assert present) seen;

  (* Verify queue is empty *)
  assert (Msqueue.pop q = None);

  Printf.printf
    "4x4 stress test passed: %d unique elements retrieved.\n"
    (4 * n)
