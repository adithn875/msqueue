
module Atomic = Dscheck.TracedAtomic

type node = {
  id : int;
  next : node option Atomic.t;
}

let () =
  Atomic.trace ~impl:`Dpor (fun () ->
    let a = { id = 0; next = Atomic.make None } in
    let b = { id = 1; next = Atomic.make None } in
    let c = { id = 2; next = Atomic.make None } in

    let head = Atomic.make a in
    let tail = Atomic.make a in

    let rec producer_a () =
      let old_tail = Atomic.get tail in
      let next = Atomic.get old_tail.next in

      if old_tail == Atomic.get tail then
        match next with
        | None ->
            if Atomic.compare_and_set old_tail.next None (Some b) then
              ignore (Atomic.compare_and_set tail old_tail b)
            else
              producer_a ()
        | Some next_node ->
            ignore (Atomic.compare_and_set tail old_tail next_node);
            producer_a ()
      else
        producer_a ()
    in

    let rec producer_b () =
      let old_tail = Atomic.get tail in
      let next = Atomic.get old_tail.next in

      if old_tail == Atomic.get tail then
        match next with
        | None ->
            if Atomic.compare_and_set old_tail.next None (Some c) then
              ignore (Atomic.compare_and_set tail old_tail c)
            else
              producer_b ()
        | Some next_node ->
    ignore (Atomic.compare_and_set tail old_tail next_node);
    producer_b ()
      else
        producer_b ()
    in

    Atomic.spawn producer_a;
    Atomic.spawn producer_b;

    Atomic.final (fun () ->
      let rec reachable current target =
        if current == target then true
        else
          match Atomic.get current.next with
          | None -> false
          | Some next -> reachable next target
      in

      Atomic.check (fun () ->
        reachable (Atomic.get head) (Atomic.get tail));

      Printf.printf "Tail is reachable from head\n"
    )
  )
