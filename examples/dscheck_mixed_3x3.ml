
module Checked = Msqueue.Make (Dscheck.TracedAtomic)

let () =
  Dscheck.TracedAtomic.trace
    ~interleavings:stdout
    (fun () ->
      let q = Checked.create () in

      let result1 = Dscheck.TracedAtomic.make None in
      let result2 = Dscheck.TracedAtomic.make None in
      let result3 = Dscheck.TracedAtomic.make None in

      (* Producer 1 *)
      Dscheck.TracedAtomic.spawn (fun () ->
        Checked.push q 10
      );

      (* Producer 2 *)
      Dscheck.TracedAtomic.spawn (fun () ->
        Checked.push q 20
      );

      (* Producer 3 *)
      Dscheck.TracedAtomic.spawn (fun () ->
        Checked.push q 30
      );

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

      (* Consumer 3 *)
      Dscheck.TracedAtomic.spawn (fun () ->
        let result = Checked.pop q in
        Dscheck.TracedAtomic.set result3 result
      );

      (* Final verification *)
      Dscheck.TracedAtomic.final (fun () ->
  let first = Dscheck.TracedAtomic.get result1 in
  let second = Dscheck.TracedAtomic.get result2 in
  let third = Dscheck.TracedAtomic.get result3 in

  (* Every consumer must return a valid result *)
  Dscheck.TracedAtomic.check (fun () ->
    List.for_all
      (fun x -> x = None || x = Some 10 || x = Some 20 || x = Some 30)
      [first; second; third]
  )
)
      )
