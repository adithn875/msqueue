(** Atomic operations required by the Michael–Scott queue. *)
module type ATOMIC = sig
  type 'a t

  val make : 'a -> 'a t
  val get : 'a t -> 'a
  val compare_and_set : 'a t -> 'a -> 'a -> bool
  val set : 'a t -> 'a -> unit
end

(** Build a Michael–Scott queue using the supplied atomic implementation. *)
module Make (A : ATOMIC) : sig
  type 'a queue

  val create : unit -> 'a queue
  val push : 'a queue -> 'a -> unit
  val pop : 'a queue -> 'a option
  val tail_reachable : 'a queue -> bool
end

(** Default implementation using OCaml's Atomic module. *)
module Default : sig
  type 'a queue

  val create : unit -> 'a queue
  val push : 'a queue -> 'a -> unit
  val pop : 'a queue -> 'a option
end

include module type of Default
