(* vim: set ft=ocaml sw=2 ts=2: *)

(* find_primes.ml
 * Find prime numbers
*)

let limit = 100_000
let num_worker = 4

open Message

module Controller = Worker_process.Master.Make(struct
    module Request = Request
    module Response = Response
    let worker_name = "worker"
  end)


let () =
  let open Lwt.Infix in
  Printf.printf "Finding prime numbers < %d (using %d worker) ..\n" limit num_worker;
  Lwt_main.run begin
    let z = Zmq.Context.create () in
    let send_sock = Zmq.Socket.create z Zmq.Socket.push
    and recv_sock = Zmq.Socket.create z Zmq.Socket.pull in
    Zmq.Socket.bind send_sock "tcp://127.0.0.1:5555";
    Zmq.Socket.bind recv_sock "tcp://127.0.0.1:5556";
    let send = Zmq_lwt.Socket.of_socket send_sock
    and recv = Zmq_lwt.Socket.of_socket recv_sock
    in
    Controller.start_worker 5555 5556 num_worker >>= fun () ->
    Controller.recv_response recv num_worker >>= fun pids ->
    List.iter (function
        | Message.Response.Ok id -> Printf.printf "[%d]: started.\n" id
        | _                      -> failwith "Missing worker response") pids;
    Lwt.return_unit >>= fun () ->
    let rec loop n =
      if n <= limit then Controller.send_request send [Num n] >>= fun () ->
        loop (n + 1)
      else Lwt.return_unit
    in
    loop 1 >>= fun () ->
    Controller.recv_response recv limit >>= fun resp ->
    let primes = List.filter (function | Message.Response.Yes _ -> true | _ -> false) resp
    in
    Printf.printf "Found %d primes.\n" (List.length primes);
    Lwt.return_unit >>= fun () ->
    Controller.send_request send (List.init num_worker (fun _ -> Message.Request.Stop)) >>= fun () ->
    Zmq.Socket.close send_sock;
    Zmq.Socket.close recv_sock;
    Zmq.Context.terminate z;
    Lwt.return_unit
  end


