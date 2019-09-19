(* message.ml
 * Request & response messages send to the prime checking worker
*)

module Request = struct

  type t =
    | Num of int
    | Stop

  let marshal (req : t) = Marshal.to_string req []
  let unmarshal str : t = Marshal.from_string str 0

end

module Response = struct

  type t =
    | Ok of int
    | Yes of int
    | No

  let marshal (req : t) = Marshal.to_string req []
  let unmarshal str : t = Marshal.from_string str 0

end

