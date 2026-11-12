
(* ========================================= *)
(* MSQueue Benchmark                         *)
(* ========================================= *)

(* Push n elements into the queue *)
let push_all queue n =
  for i = 0 to n - 1 do
    Msqueue.push queue i
  done

(* Pop n elements and verify FIFO order *)
let pop_all queue n =
  for i = 0 to n - 1 do
    match Msqueue.pop queue with
    | Some value ->
        if value <> i then
          failwith "FIFO order violation"
    | None ->
        failwith "Queue became empty too early"
  done

(* Producer: pushes n unique values *)
let producer queue start n =
  for i = start to start + n - 1 do
    Msqueue.push queue i
  done

(* Consumer: retrieves n values *)
let consumer queue n =
  let received = ref [] in
  let count = ref 0 in

  while !count < n do
    match Msqueue.pop queue with
    | Some value ->
        received := value :: !received;
        incr count
    | None ->
        Domain.cpu_relax ()
  done;

  !received

(* Verify every expected value was received exactly once *)
let verify_results results n =
  let sorted = List.sort compare results in
  let expected = List.init n Fun.id in

  if sorted <> expected then
    failwith "Concurrent benchmark correctness check failed"

(* Calculate median of 10 measurements *)
let calculate_median results =
  let sorted = List.sort Float.compare results in
  (List.nth sorted 4 +. List.nth sorted 5) /. 2.0

(* ========================================= *)
(* Sequential Benchmark                      *)
(* ========================================= *)

let run_sequential_once n =
  let queue = Msqueue.create () in

  let start = Unix.gettimeofday () in

  push_all queue n;
  pop_all queue n;

  let finished = Unix.gettimeofday () in
  let elapsed = finished -. start in

  let total_operations = 2. *. float_of_int n in
  total_operations /. elapsed

let run_sequential n =
  ignore (run_sequential_once n);

  let results =
    List.init 10 (fun _ -> run_sequential_once n)
  in

  let median = calculate_median results in

  Printf.printf "\nSequential benchmark\n";
  Printf.printf "Elements: %d\n" n;
  Printf.printf "Measurements: 10\n";
  Printf.printf "Median throughput: %.0f operations/second\n" median

(* ========================================= *)
(* 1 Producer + 1 Consumer                   *)
(* ========================================= *)

let run_1p1c_once n =
  let queue = Msqueue.create () in

  let start = Unix.gettimeofday () in

  let producer_domain =
    Domain.spawn (fun () -> producer queue 0 n)
  in

  let consumer_domain =
    Domain.spawn (fun () -> consumer queue n)
  in

  Domain.join producer_domain;
  let results = Domain.join consumer_domain in

  let finished = Unix.gettimeofday () in
  let elapsed = finished -. start in

  verify_results results n;

  let total_operations = 2. *. float_of_int n in
  total_operations /. elapsed

let run_1p1c n =
  ignore (run_1p1c_once n);

  let results =
    List.init 10 (fun _ -> run_1p1c_once n)
  in

  let median = calculate_median results in

  Printf.printf "\nConcurrent benchmark: 1P + 1C\n";
  Printf.printf "Elements per producer: %d\n" n;
  Printf.printf "Measurements: 10\n";
  Printf.printf "Correctness check: PASSED\n";
  Printf.printf "Median throughput: %.0f operations/second\n" median

(* ========================================= *)
(* 2 Producers + 2 Consumers                  *)
(* ========================================= *)

let run_2p2c_once n =
  let queue = Msqueue.create () in

  let start = Unix.gettimeofday () in

  let producer1 =
    Domain.spawn (fun () -> producer queue 0 n)
  in

  let producer2 =
    Domain.spawn (fun () -> producer queue n n)
  in

  let consumer1 =
    Domain.spawn (fun () -> consumer queue n)
  in

  let consumer2 =
    Domain.spawn (fun () -> consumer queue n)
  in

  Domain.join producer1;
  Domain.join producer2;

  let results1 = Domain.join consumer1 in
  let results2 = Domain.join consumer2 in

  let results = results1 @ results2 in

  let finished = Unix.gettimeofday () in
  let elapsed = finished -. start in

  verify_results results (2 * n);

  let total_operations = 4. *. float_of_int n in
  total_operations /. elapsed

let run_2p2c n =
  ignore (run_2p2c_once n);

  let results =
    List.init 10 (fun _ -> run_2p2c_once n)
  in

  let median = calculate_median results in

  Printf.printf "\nConcurrent benchmark: 2P + 2C\n";
  Printf.printf "Elements per producer: %d\n" n;
  Printf.printf "Total pushes: %d\n" (2 * n);
  Printf.printf "Total pops: %d\n" (2 * n);
  Printf.printf "Measurements: 10\n";
  Printf.printf "Correctness check: PASSED\n";
  Printf.printf "Median throughput: %.0f operations/second\n" median

(* ========================================= *)
(* 4 Producers + 4 Consumers                  *)
(* ========================================= *)

let run_4p4c_once n =
  let queue = Msqueue.create () in

  let start = Unix.gettimeofday () in

  (* Four producers with unique value ranges *)
  let producer1 =
    Domain.spawn (fun () -> producer queue 0 n)
  in

  let producer2 =
    Domain.spawn (fun () -> producer queue n n)
  in

  let producer3 =
    Domain.spawn (fun () -> producer queue (2 * n) n)
  in

  let producer4 =
    Domain.spawn (fun () -> producer queue (3 * n) n)
  in

  (* Four consumers *)
  let consumer1 =
    Domain.spawn (fun () -> consumer queue n)
  in

  let consumer2 =
    Domain.spawn (fun () -> consumer queue n)
  in

  let consumer3 =
    Domain.spawn (fun () -> consumer queue n)
  in

  let consumer4 =
    Domain.spawn (fun () -> consumer queue n)
  in

  (* Wait for producers *)
  Domain.join producer1;
  Domain.join producer2;
  Domain.join producer3;
  Domain.join producer4;

  (* Collect consumer results *)
  let results1 = Domain.join consumer1 in
  let results2 = Domain.join consumer2 in
  let results3 = Domain.join consumer3 in
  let results4 = Domain.join consumer4 in

  let results =
    results1 @ results2 @ results3 @ results4
  in

  let finished = Unix.gettimeofday () in
  let elapsed = finished -. start in

  verify_results results (4 * n);

  let total_operations = 8. *. float_of_int n in
  total_operations /. elapsed

let run_4p4c n =
  ignore (run_4p4c_once n);

  let results =
    List.init 10 (fun _ -> run_4p4c_once n)
  in

  let median = calculate_median results in

  Printf.printf "\nConcurrent benchmark: 4P + 4C\n";
  Printf.printf "Elements per producer: %d\n" n;
  Printf.printf "Total pushes: %d\n" (4 * n);
  Printf.printf "Total pops: %d\n" (4 * n);
  Printf.printf "Measurements: 10\n";
  Printf.printf "Correctness check: PASSED\n";
  Printf.printf "Median throughput: %.0f operations/second\n" median

(* ========================================= *)
(* Main                                      *)
(* ========================================= *)

let () =
  let total_elements = 40_000 in

  run_sequential total_elements;
  run_1p1c total_elements;
  run_2p2c (total_elements / 2);
  run_4p4c (total_elements / 4)