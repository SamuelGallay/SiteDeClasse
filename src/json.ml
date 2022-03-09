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
