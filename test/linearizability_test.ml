open Lin

module QueueSpec = struct
  type t = int Msqueue.queue

  (* Create a fresh queue for each test *)
  let init () =
    Msqueue.create ()

  let cleanup _ =
    ()

  (* Describe the operations QCheck-Lin should test *)
  let api = [
    val_ "push" Msqueue.push
      (t @-> int @-> returning_ unit);

    val_ "pop" Msqueue.pop
      (t @-> returning (option int));
  ]
end

(* Build the QCheck-Lin test module *)
module QueueLin = Lin_domain.Make (QueueSpec)
let ()=
QCheck_base_runner.run_tests_main [
  QueueLin.lin_test
  ~count:100
  ~name: "MSQueue linearizability"
]