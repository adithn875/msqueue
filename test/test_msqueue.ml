let test_empty_queue () =
  let q = Msqueue.create () in
  assert (Msqueue.pop q = None)

let test_fifo () =
  let q = Msqueue.create () in
  Msqueue.push q 10;
  Msqueue.push q 20;
  Msqueue.push q 30;

  assert (Msqueue.pop q = Some 10);
  assert (Msqueue.pop q = Some 20);
  assert (Msqueue.pop q = Some 30);
  assert (Msqueue.pop q = None)

let test_mixed_operation () =
  let q = Msqueue.create () in
  Msqueue.push q 10;
  Msqueue.push q 20;

  assert (Msqueue.pop q = Some 10);

  Msqueue.push q 30;

  assert (Msqueue.pop q = Some 20);
  assert (Msqueue.pop q = Some 30);
  assert (Msqueue.pop q = None)

let test_reuse_after_empty () =
  let q = Msqueue.create () in
  Msqueue.push q 10;

  assert (Msqueue.pop q = Some 10);
  assert (Msqueue.pop q = None);

  Msqueue.push q 20;

  assert (Msqueue.pop q = Some 20);
  assert (Msqueue.pop q = None)
let test_large_sequential_workload () =
  let q = Msqueue.create () in

  for i = 1 to 10_000 do
    Msqueue.push q i
  done;

  for i = 1 to 10_000 do
    assert (Msqueue.pop q = Some i)
  done;

  assert (Msqueue.pop q = None)


  let test_concurrent_producers () =
  let q = Msqueue.create () in
  let n = 10_000 in

  let d1 =
    Domain.spawn (fun () ->
      for i = 0 to n - 1 do
        Msqueue.push q i
      done)
  in

  let d2 =
    Domain.spawn (fun () ->
      for i = n to (2 * n) - 1 do
        Msqueue.push q i
      done)
  in

  Domain.join d1;
  Domain.join d2;

  let seen = Array.make (2 * n) false in

  for _ = 1 to 2 * n do
    match Msqueue.pop q with
    | None ->
        failwith "Queue lost an element"
    | Some value ->
        assert (value >= 0 && value < 2 * n);
        assert (not seen.(value));
        seen.(value) <- true
  done;

  assert (Msqueue.pop q = None);

  Array.iter (fun present -> assert present) seen
let test_concurrent_consumers () =
  let q = Msqueue.create () in
  let n = 20_000 in

  (* Producer *)
  for i = 0 to n - 1 do
    Msqueue.push q i
  done;

  (* Shared results *)
  let seen = Array.make n false in
  let lock = Mutex.create () in

  (* Consumer function *)
  let consume () =
    let rec loop () =
      match Msqueue.pop q with
      | None -> ()
      | Some value ->
          Mutex.lock lock;
          assert (value >= 0 && value < n);
          assert (not seen.(value));
          seen.(value) <- true;
          Mutex.unlock lock;
          loop ()
    in
    loop ()
  in

  let c1 = Domain.spawn consume in
  let c2 = Domain.spawn consume in

  Domain.join c1;
  Domain.join c2;

  Array.iter (fun present -> assert present) seen;
  assert (Msqueue.pop q = None)

let test_concurrent_producers_consumers () =
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

  (* Consumer function *)
  let consume () =
    let rec loop () =
      match Msqueue.pop q with

      | Some value ->
          assert (value >= 0 && value < 2 * n);

          Mutex.lock lock;
          Fun.protect
            ~finally:(fun () -> Mutex.unlock lock)
            (fun () ->
              assert (not seen.(value));
              seen.(value) <- true);

          loop ()

      | None ->
          if Atomic.get producers_finished = 2 then
            ()
          else
            loop ()
    in
    loop ()
  in

  (* Spawn producers *)
  let p1 = Domain.spawn (fun () -> producer 0) in
  let p2 = Domain.spawn (fun () -> producer n) in

  (* Spawn consumers *)
  let c1 = Domain.spawn consume in
  let c2 = Domain.spawn consume in

  (* Wait for all domains *)
  Domain.join p1;
  Domain.join p2;
  Domain.join c1;
  Domain.join c2;

  (* Verify results *)
  Array.iter (fun present -> assert present) seen;
  assert (Msqueue.pop q = None)

  let () =
  test_empty_queue ();
  test_fifo ();
  test_mixed_operation ();
  test_reuse_after_empty ();
  test_large_sequential_workload ();
  test_concurrent_producers ();
  test_concurrent_consumers ();
  test_concurrent_producers_consumers ();
  print_endline "All basic tests passed!"