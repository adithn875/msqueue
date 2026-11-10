
module Checked = Msqueue.Make (Dscheck.TracedAtomic)

let () =
  Dscheck.TracedAtomic.trace
  ~interleavings:stdout
  (fun () ->
    let q = Checked.create () in
    let result1 = Dscheck.TracedAtomic.make None in
    let result2 = Dscheck.TracedAtomic.make None in

    (* Producer 1 *)
    Dscheck.TracedAtomic.spawn (fun () ->
      Checked.push q 10
    );

    (* Producer 2 *)
    Dscheck.TracedAtomic.spawn (fun () ->
      Checked.push q 20
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

    (* Verify results after all processes finish *)
    Dscheck.TracedAtomic.final (fun () ->
      let first = Dscheck.TracedAtomic.get result1 in
      let second = Dscheck.TracedAtomic.get result2 in

      (* Each consumer returns a valid result *)
      Dscheck.TracedAtomic.check (fun () ->
        (first = None || first = Some 10 || first = Some 20)
        &&
        (second = None || second = Some 10 || second = Some 20)
      );

      (* Consumers cannot receive the same value *)
      Dscheck.TracedAtomic.check (fun () ->
        match first, second with
        | Some a, Some b -> a <> b
        | _ -> true
      );

      (* Inspect remaining queue contents *)
      let remaining1 = Checked.pop q in
      let remaining2 = Checked.pop q in

      let results = [first; second; remaining1; remaining2] in

      (* Every pushed value must appear exactly once *)
      Dscheck.TracedAtomic.check (fun () ->
        List.filter ((=) (Some 10)) results |> List.length = 1
        &&
        List.filter ((=) (Some 20)) results |> List.length = 1
      );

      (* No unexpected values should remain *)
      Dscheck.TracedAtomic.check (fun () ->
        Checked.pop q = None
      )
    )
  )
