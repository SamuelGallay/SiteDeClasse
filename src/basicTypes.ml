module StringMap = Map.Make (String)

type token = { token : string; expiration : float }
type page = { id : string; name : string; endpoint : string; mutable markdown : string }

type session = {
  mutable messages : string list;
  mutable active_page : page;
  mutable connected : bool;
  mutable csrf : string;
}

(* Passwords *)
type user = { pseudo : string; hashed_password : string } [@@deriving yojson]
type user_list = user list [@@deriving yojson]

type memory = {
  mutable pages : page StringMap.t;
  mutable document_list : (string * string) list;
  mutable sessions : session StringMap.t;
  mutable users : user StringMap.t;
}

(* Crypto File *)

type private_key = { private_key : string } [@@deriving yojson] [@@yojson.allow_extra_fields]
type header = { alg : string; typ : string } [@@deriving yojson]

type claim_set = { iss : string; scope : string; aud : string; exp : int; iat : int }
[@@deriving yojson]

type access_token = { access_token : string } [@@deriving yojson] [@@yojson.allow_extra_fields]

(* Storage File *)

type storage_object = { name : string; mediaLink : string }
[@@deriving yojson] [@@yojson.allow_extra_fields]

type object_list = { kind : string; items : storage_object list } [@@deriving yojson]

let ( let* ) = Lwt.bind
