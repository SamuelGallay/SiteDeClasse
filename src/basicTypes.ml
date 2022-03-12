module StringMap = Map.Make (String)

type token = { token : string; expiration : float }
type page = { id : string; name : string; endpoint : string; mutable markdown : string }

type session = {
  mutable messages : string list;
  mutable active_page : page;
  mutable connected : bool;
  mutable csrf : string;
}

type memory = {
  mutable pages : page StringMap.t;
  mutable document_list : (string * string) list;
  mutable sessions : session StringMap.t;
}

let ( let* ) = Lwt.bind
