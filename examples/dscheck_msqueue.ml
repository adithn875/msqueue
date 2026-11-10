
module Checked = Msqueue.Make (Dscheck.TracedAtomic)
let () =
  (* DSCheck concurrent test *)
  Dscheck.TracedAtomic.trace (fun () ->
    let q = Checked.create () in

    (* Check initial queue invariant *)
    Dscheck.TracedAtomic.check (fun () ->
      Checked.tail_reachable q
    );

    (* Check invariant between scheduling steps *)
    Dscheck.TracedAtomic.every (fun () ->
      Dscheck.TracedAtomic.check (fun () ->
        Checked.tail_reachable q
      )
    );

    (* Producer 1 *)
    Dscheck.TracedAtomic.spawn (fun () ->
      Checked.push q 10
    );

    (* Producer 2 *)
    Dscheck.TracedAtomic.spawn (fun () ->
      Checked.push q 20
    );

    (* Check final queue contents *)
    Dscheck.TracedAtomic.final (fun () ->
      let first = Checked.pop q in
      let second = Checked.pop q in

      Dscheck.TracedAtomic.check (fun () ->
        (first = Some 10 && second = Some 20)
        ||
        (first = Some 20 && second = Some 10)
      )
    )
  )
