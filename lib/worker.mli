(* vim: set ft=ocaml sw=2 ts=2: *)

(** worker.mli
    Functor and module types with boilerplate code for starting, communicating
    and stopping worker processes.
    Communication is done via ZeroMQ messages.
*)

module type Processor = sig

  val name : string
  (** Name of the worker process. *)

  val version : string
  (** Version info (as string) for the worker process. *)

  val loop : verbose : bool -> [`Pull] Zmq_lwt.Socket.t -> [`Push] Zmq_lwt.Socket.t -> unit Lwt.t
  (** [loop ~v recv send] is a callback to read requests from the [recv] socket, process them
      and send the answer to the [send] socket. Communication is done via ZeroMQ push/pull sockets.
      When [loop] returns the respective worker process ends. [~v] is a flag to control verbose output, e.g.,
      on the console. *)
end
(** Input signature of the functor {!Worker.Make} *)


module type S = sig

  val run : unit -> unit
  (** [run ()] starts the defined worker process. *)

end
(** Output signature of the functor {!Worker.Make} *)


module Make : functor (P : Processor) -> S
(** Functor building a module for a worker process with the given data processor. *)
