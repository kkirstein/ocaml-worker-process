(* worker.ml
 * A worker process to check for prime numbers
*)

open Message

let is_prime n =
  let limit = int_of_float (sqrt (float_of_int n)) in
  if n <= 1 then false else
    let rec loop i =
      if i > limit then true else
      if n mod i = 0 then false else loop (i + 1)
    in
    loop 2


module Prime_worker = Worker_process.Worker.Make(struct
    let name = "prime_worker"
    let version = "0.1.0"

    let loop ~verbose recv send =
      let pid = Unix.getpid () in
      let open Lwt.Infix in
      Zmq_lwt.Socket.send send (Response.marshal (Ok pid )) >>= fun () ->
      if verbose then Lwt_io.printl (Printf.sprintf "[%d]: worker started." pid) else Lwt.return_unit >>= fun () ->
      let rec inner_loop () =
        Zmq_lwt.Socket.recv recv >>= fun req ->
        match Request.unmarshal req with
        | Num n -> (if is_prime n then
            Zmq_lwt.Socket.send send (Response.marshal (Yes n))
          else Zmq_lwt.Socket.send send (Response.marshal No)) >>= fun () -> inner_loop ()
        | Stop  -> if verbose then Lwt_io.printl (Printf.sprintf "[%d]: worker stopped." pid) else Lwt.return_unit
      in
    inner_loop ()
  end)


let () = Prime_worker.run ()

