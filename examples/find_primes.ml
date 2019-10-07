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
    let tic = Sys.time () in
    let z = Zmq.Context.create () in
    Controller.start_worker z 5555 5556 num_worker >>= fun (send, recv) -> begin
      Controller.recv_response recv num_worker >>= fun pids ->
      List.iter (function
          | Message.Response.Ok id -> Printf.printf "[%d]: started.\n" id
          | _                      -> failwith "Missing worker response") pids;
      Lwt.return_unit >>= fun () ->
      let toc = Sys.time () in
      Printf.printf "%d worker started in %.3fs.\n" num_worker (toc -. tic);
      let tic = Sys.time () in
      let reqs = List.init limit (fun x -> Message.Request.Num (x + 1)) in
      let sent = Controller.send_request send reqs
      and received = Controller.recv_response recv limit in
      sent >>= fun () ->
      received >>= fun resp ->
      let primes = List.filter (function | Message.Response.Yes _ -> true | _ -> false) resp
      in
      let toc = Sys.time () in
      Printf.printf "Found %d primes (%.3fs).\n" (List.length primes) (toc -. tic);
      Lwt.return_unit >>= fun () ->
      Controller.send_request send (List.init num_worker (fun _ -> Message.Request.Stop)) >>= fun () ->
      Controller.close send recv >>= fun () ->
      Zmq.Context.terminate z;
      Lwt.return_unit
    end
  end


