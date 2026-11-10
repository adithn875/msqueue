
module Checked = Msqueue.Make (Dscheck.TracedAtomic)

let () =
  Dscheck.TracedAtomic.trace (fun () ->
    let q = Checked.create () in

    (* Populate the queue first *)
    Checked.push q 10;
    Checked.push q 20;

    (* Atomic result slots *)
    let result1 = Dscheck.TracedAtomic.make None in
    let result2 = Dscheck.TracedAtomic.make None in

    (* Consumer 1 *)
    Dscheck.TracedAtomic.spawn (fun () ->
      let result = Checked.pop q in
      Dscheck.TracedAtomic.set result1 result
    );

    (* Consumer 2 *)
    Dscheck.TracedAtomic.spawn (fun () ->
      let result = Checked.pop q in
      Dscheck.TracedAtomic.set result2 result
    );

    (* Verify both consumers received distinct values *)
    Dscheck.TracedAtomic.final (fun () ->
      let first = Dscheck.TracedAtomic.get result1 in
      let second = Dscheck.TracedAtomic.get result2 in

      Dscheck.TracedAtomic.check (fun () ->
        (first = Some 10 && second = Some 20)
        ||
        (first = Some 20 && second = Some 10)
      )
    )
  )
