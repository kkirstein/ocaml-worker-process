(* vim: set ft=ocaml sw=2 ts=2: *)

(** master.mli
    Functor and module types with boilerplate code for controlling
    (starting, sneding requests, receiving response, and stopping)
    worker processes.
    Communication is done via ZeroMQ messages.
*)

module type Controller = sig

  module Request : sig
    type t
    (** Abstract type of a request message *)

    val marshal : t -> string
    (** Marshal request message as string *)
  end
  (** Submodule for request messages *)

  module Response : sig
    type t
    (** Abstract type of a response message *)

    val unmarshal : string -> t
    (** Un-marshal response message from string *)
  end
  (** Submodule for request messages *)

  val worker_name : string
  (** Name of the worker process. *)

end
(** Input signature of the functor {!Master.Make} *)


module type S = sig

  type request
  (** Abstract type of a request message *)

  type response
  (** Abstract type of a response message *)


  val start_worker : Zmq.Context.t -> int -> int -> int ->
    ([>`Push] Zmq_lwt.Socket.t * [>`Pull] Zmq_lwt.Socket.t) Lwt.t
  (** [start_worker z send_port recv_port n] starts [n]
      processes, which listen on local port [recv_port] and send to [send_port].
      [z] is the ZMQ context to be used. [start_worker] returns a pair of [(send, recv)] sockets
      for communication with the worker processes.  *)


  val send_request : [`Push] Zmq_lwt.Socket.t -> request list -> unit Lwt.t
  (** [send_request sock msgs] sends [msgs] over network socket [sock] to
      a worker process. *)


  val recv_response : [`Pull] Zmq_lwt.Socket.t -> int -> response list Lwt.t
  (** [recv_response sock num] receives [num] response messages from network
      socket [sock]. *)

  val close : 'a Zmq_lwt.Socket.t -> 'b Zmq_lwt.Socket.t -> unit Lwt.t
  (** [close s1 s2] closes the given ZMQ sockets *)

end
(** Output signature of the functor {!Master.Make} *)


module Make : functor (C : Controller) -> S
  with type request := C.Request.t
   and type response := C.Response.t
(** Functor building a module for a master to control worker processes. *)

