(* vim: set ft=ocaml sw=2 ts=2: *)

(* find_primes.ml
 * Find prime numbers
*)

let limit = 100_000
let num_worker = 4

open Lwt.Infix
open Message

module Controller = Worker_process.Master.Make(struct
    module Request = Request
    module Response = Response
    let worker_name = "worker"
  end)

let find_primes z limit num_worker =
  Printf.printf "Finding prime numbers < %d (using %d worker) ..\n" limit num_worker;
  let tic = Sys.time () in
  Controller.start_worker z 5555 5556 num_worker >>= fun (send, recv) -> begin
    Controller.recv_response recv num_worker >>= fun pids ->
    Lwt.return (List.iter (function
        | Message.Response.Ok _ -> ()
        | _                     -> failwith "Missing worker response") pids) >>= fun () ->
    let rec loop n =
      if n <= limit then Controller.send_request send [Num n] >>= fun () ->
        loop (n + 1)
      else Lwt.return_unit
    in
    loop 1 >>= fun () ->
    Controller.recv_response recv limit >>= fun resp ->
    let primes = List.filter (function | Message.Response.Yes _ -> true | _ -> false) resp
    in
    let toc = Sys.time () in
    Printf.printf "Found %d primes (%.3fs).\n" (List.length primes) (toc -. tic);
    Lwt.return_unit >>= fun () ->
    Controller.send_request send (List.init num_worker (fun _ -> Message.Request.Stop)) >>= fun () ->
    Controller.close send recv >>= fun () ->
    Lwt.return_unit
  end


let () =
  let z = Zmq.Context.create () in
  Lwt_main.run begin
    find_primes z 100_000 1 >>= fun () ->
    find_primes z 100_000 2 >>= fun () ->
    find_primes z 100_000 4 >>= fun () ->
    find_primes z 100_000 8 >>= fun () ->
    find_primes z 1_000 4 >>= fun () ->
    find_primes z 10_000 4
  end;
  Zmq.Context.terminate z


