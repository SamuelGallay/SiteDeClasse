module StringMap = Map.Make (String)

type token = { token : string; expiration : float }

type session = {
  mutable messages : string list;
  mutable active_page : string;
  mutable connected : bool;
  mutable csrf : string;
}

type memory = {
  mutable token : token option;
  page_list : string list;
  mutable document_list : (string * string) list;
  mutable sessions : session StringMap.t;
}

let ( let* ) = Lwt.bind
