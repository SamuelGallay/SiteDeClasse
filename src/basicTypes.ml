module StringMap = Map.Make (String)

type token = { token : string; expiration : float }

let ( let* ) = Lwt.bind
