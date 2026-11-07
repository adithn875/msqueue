
type 'a node = {
  value : 'a option;
  next : 'a node option Atomic.t;
}

type 'a queue = {
  head : 'a node Atomic.t;
  tail : 'a node Atomic.t;
}
let create () =
  let dummy = {
    value = None;
    next = Atomic.make None
  } in
  let queue = {
    head = Atomic.make dummy;
    tail = Atomic.make dummy
  } in
  queue

let push q value =
  let new_node = {
    value = Some value;
    next = Atomic.make None
  } in

  let rec loop () =
    let tail = Atomic.get q.tail in
    let tail_next = Atomic.get tail.next in

    if tail == Atomic.get q.tail then
      match tail_next with
      | None ->
          if Atomic.compare_and_set tail.next None (Some new_node) then (
            let _ = Atomic.compare_and_set q.tail tail new_node in
            ()
          )
          else
            loop ()

      | Some next_node ->
          let _ = Atomic.compare_and_set q.tail tail next_node in
          loop ()
    else
      loop ()
  in
  loop ()
let pop q =
  let rec loop () =
    let head = Atomic.get q.head in
    let tail = Atomic.get q.tail in
    let next = Atomic.get head.next in

    if head == Atomic.get q.head then
      if head == tail then
        match next with
        | None -> None
        | Some next_node ->
            let _ = Atomic.compare_and_set q.tail tail next_node in
            loop ()
      else
        match next with
        | None -> loop ()
        | Some next_node ->
            let value = next_node.value in
            if Atomic.compare_and_set q.head head next_node then
              value
            else
              loop ()
    else
      loop ()
  in
  loop ()
