open Cohttp
open Cohttp_lwt_unix

type storage_object = { name : string; mediaLink : string }
[@@deriving yojson, show] [@@yojson.allow_extra_fields]

type object_list = { kind : string; items : storage_object list }
[@@deriving yojson, show]

let ( let* ) = Lwt.bind

let api =
  "https://storage.googleapis.com/storage/v1/b/erudite-descent-342509-public-bucket/o"

let get_objects () =
  let* resp, body = Client.get (Uri.of_string api) in
  let code = Code.code_of_status (Response.status resp) in
  Dream.log "Object list %d" code;
  let* json_string = Cohttp_lwt.Body.to_string body in
  let json_safe = Yojson.Safe.from_string json_string in
  let obj_list = object_list_of_yojson json_safe in
  Dream.log "\n%s" (show_object_list obj_list);
  Lwt.return (List.map (fun o -> (o.name, o.mediaLink)) obj_list.items)
