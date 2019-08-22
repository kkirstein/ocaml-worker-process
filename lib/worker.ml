(* vim: set ft=ocaml sw=2 ts=2: *)

(** worker.ml
    Functor implementation with boilerplate code for starting, communicating
    and stopping worker processes.
    Communication is done via ZeroMQ messages.
*)

open Cmdliner

module type Processor = sig
  val name : string
  val version : string
  val loop : verbose : bool -> [`Pull] Zmq_lwt.Socket.t -> [`Push] Zmq_lwt.Socket.t -> unit Lwt.t
end


module type S = sig
  val run : unit -> unit
end


module Make(P: Processor) = struct

  (* a simple console logger *)
  let lwt_verbose ?(verbose=true) msg =
    if verbose then Lwt_io.printl msg else Lwt.return_unit

  (* entry point *)
  let main verbose in_port out_port = 
    let pid = Unix.getpid () in
    Lwt_main.run begin
      let open Lwt.Infix in
      let z = Zmq.Context.create () in
      let in_socket = Zmq.Socket.create z Zmq.Socket.pull
      and out_socket = Zmq.Socket.create z Zmq.Socket.push in
      Zmq.Socket.connect in_socket ("tcp://127.0.0.1:" ^ (string_of_int in_port));
      Zmq.Socket.connect out_socket ("tcp://127.0.0.1:" ^ (string_of_int out_port));
      lwt_verbose ~verbose (Printf.sprintf "[%d]: Listening on port: %d\n" pid in_port) >>= fun () ->
      lwt_verbose ~verbose (Printf.sprintf "[%d]: Sending to port: %d\n" pid out_port) >>= fun () ->
      let recv = Zmq_lwt.Socket.of_socket in_socket
      and send = Zmq_lwt.Socket.of_socket out_socket in
      P.loop ~verbose recv send >>= fun () ->
      Zmq.Socket.close in_socket;
      Zmq.Socket.close out_socket;
      Zmq.Context.terminate z |> Lwt.return
    end

  (* cmdliner options *)
  let verbose =
    let doc = "Print status information to STDOUT" in
    Arg.(value & flag & info ["v"; "verbose"] ~doc)

  let in_port =
    let doc = "Port on which worker is receiving input data." in
    Arg.(required & pos 0 (some int) None & info [] ~docv:"IN_PORT" ~doc)

  let out_port =
    let doc = "Port on which worker is sending its data." in
    Arg.(required & pos 1 (some int) None & info [] ~docv:"OUT_PORT" ~doc)

  let cmd =
    let doc = "Starts a worker process" in
    let man = [
      `S "DESCRIPTION";
      `P "$(tname) reads requests from given IN_PORT and
        sends response to given OUT_PORT.";
      `P "If $(b,VERBOSE) is given, status information of the worker is
        printed to STDOUT"
    ]
    in
    Term.(const main $ verbose $ in_port $ out_port),
    Term.info P.name ~version:P.version ~doc ~man


  let run () =
    match Term.eval cmd with
    | `Error _  -> exit 1
    | _         -> exit 0
end
