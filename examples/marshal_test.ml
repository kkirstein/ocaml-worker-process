(* vim: set ft=ocaml sw=2 ts=2: *)

(* marshal_test.ml
 * Test performance of message marshalling
*)

let limit = 100_000
let num_worker = 4


let () =
  let tic = Sys.time () in
  let reqs = List.init limit (fun x -> Message.Request.Num (x + 1)) in
  let reqs_str = List.map Message.Request.marshal reqs in
  let toc = Sys.time () in
  Printf.printf "Marshalled %d messages (%.3fs).\n" (List.length reqs_str) (toc -. tic);
  ()
