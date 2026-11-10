module type ATOMIC = sig
  type 'a t

  val make : 'a -> 'a t
  val get : 'a t -> 'a
  val compare_and_set : 'a t -> 'a -> 'a -> bool
  val set : 'a t -> 'a -> unit
end

module Std_atomic = struct
  type 'a t = 'a Atomic.t
  let make = Atomic.make
  let get = Atomic.get
  let compare_and_set = Atomic.compare_and_set
  let set = Atomic.set
end
module Check : ATOMIC = Std_atomic
module Make (A: ATOMIC) = struct
  type 'a node = {
  value : 'a option;
  next : 'a node option A.t;
}
type 'a queue = {
  head : 'a node A.t;
  tail : 'a node A.t;
}
let create () =
  let dummy = {
    value = None;
    next = A.make None
  } in
  let queue = {
    head = A.make dummy;
    tail = A.make dummy
  } in
  queue
let push q value =
  let new_node = {
    value = Some value;
    next = A.make None
  } in

  let rec loop () =
    let tail = A.get q.tail in
    let tail_next = A.get tail.next in

    if tail == A.get q.tail then
      match tail_next with
      | None ->
          if A.compare_and_set tail.next None (Some new_node) then (
            let _ = A.compare_and_set q.tail tail new_node in
            ()
          )
          else
            loop ()

      | Some next_node ->
          let _ = A.compare_and_set q.tail tail next_node in
          loop ()
    else
      loop ()
  in
  loop ()

let pop q =
  let rec loop () =
    let head = A.get q.head in
    let tail = A.get q.tail in
    let next = A.get head.next in

    if head == A.get q.head then
      if head == tail then
        match next with
        | None -> None
        | Some next_node ->
            let _ = A.compare_and_set q.tail tail next_node in
            loop ()
      else
        match next with
        | None -> loop ()
        | Some next_node ->
            let value = next_node.value in
            if A.compare_and_set q.head head next_node then
              value
            else
              loop ()
    else
      loop ()
  in
  loop ()


let tail_reachable q =
  let head = A.get q.head in
  let tail = A.get q.tail in

  let rec walk current visited  =
    if current == tail then true
    else if List.exists (fun node -> node == current) visited then false
    else
      match A.get current.next  with
      |None -> false
      |Some next_node -> walk next_node (current:: visited)
  in
  walk head []

end
module Default = Make (Std_atomic)
include Default
