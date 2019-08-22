(* vim: set ft=ocaml sw=2 ts=2: *)

(** master.ml
    Functor implementation with boilerplate code for controlling
    (starting, sneding requests, receiving response, and stopping)
    worker processes.
    Communication is done via ZeroMQ messages.
*)

module type Controller = sig
  module Request : sig
    type t
    val marshal : t -> string
  end
  module Response : sig
    type t
    val unmarshal : string -> t
  end
  val worker_name : string
end

module type S = sig
  type request
  type response
  val start_worker : int -> int -> int -> unit Lwt.t
  val send_request : [`Push] Zmq_lwt.Socket.t -> request list -> unit Lwt.t
  val recv_response : [`Pull] Zmq_lwt.Socket.t -> int -> response list Lwt.t
end


module Make(C : Controller) = struct

  open Lwt.Infix

  let start_worker send_port recv_port num_worker =
    let exe_dir = Sys.executable_name |> Filename.dirname in
    let worker_path = Filename.concat exe_dir C.worker_name in
    let rec loop n =
      let cmd_str = match Sys.os_type with
        | "Unix"      -> String.concat " " [worker_path;
                                            (string_of_int send_port);
                                            (string_of_int recv_port); " &"]
        | "Cygwin"    -> String.concat " " [worker_path;
                                            (string_of_int send_port);
                                            (string_of_int recv_port); " &"]
        | "Win32"     -> String.concat " " ["start /b"; (worker_path ^ ".exe");
                                            (string_of_int send_port);
                                            (string_of_int recv_port)]
        | _            -> failwith "Unsupported system, cannot start worker"
      in
      if n > 0 then
        Lwt_unix.system cmd_str >>= fun _ -> loop (n - 1)
      else Lwt.return_unit
    in
    loop num_worker


  let send_request sock msgs =
    let rec loop msgs = match msgs with
      | h :: t  -> Zmq_lwt.Socket.send sock (C.Request.marshal h) >>= fun () -> loop t
      | []      -> Lwt.return_unit
    in
    loop msgs


  let recv_response sock num =
    let rec loop n acc =
      if n > 0 then Zmq_lwt.Socket.recv sock >>= fun str ->
        let resp = C.Response.unmarshal str in
        loop (n - 1) (resp :: acc)
      else Lwt.return (List.rev acc)
    in
    loop num []


end
