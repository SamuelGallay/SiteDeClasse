open Cohttp
open Cohttp_lwt_unix

let sprintf = Format.sprintf
let ( let* ) = Lwt.bind

type storage_object = { name : string; mediaLink : string }
[@@deriving yojson, show] [@@yojson.allow_extra_fields]

type object_list = { kind : string; items : storage_object list }
[@@deriving yojson, show]

let get_objects () =
  let api =
    "https://storage.googleapis.com/storage/v1/b/erudite-descent-342509-public-bucket/o"
  in
  let* resp, body = Client.get (Uri.of_string api) in
  let code = Code.code_of_status (Response.status resp) in
  Dream.log "Object list %d" code;
  let* json_string = Cohttp_lwt.Body.to_string body in
  let json_safe = Yojson.Safe.from_string json_string in
  let obj_list = object_list_of_yojson json_safe in
  (* Dream.log "\n%s" (show_object_list obj_list); *)
  Lwt.return (List.map (fun o -> (o.name, o.mediaLink)) obj_list.items)

let push_file name content =
  let jwt = Crypto.form_jwt () in
  let* token = Crypto.get_token jwt in
  let url =
    "https://storage.googleapis.com/upload/storage/v1/b/erudite-descent-342509-public-bucket/o"
  in
  let uri =
    Uri.with_query' (Uri.of_string url)
      [ ("name", name); ("uploadType", "media") ]
  in
  let* resp, body =
    Client.post
      ~headers:
        (Header.of_list
           [
             ("Content-Type", Magic_mime.lookup name);
             ("Authorization", sprintf "Bearer %s" token);
           ])
      ~body:(`String content) uri
  in
  let _body_string = Cohttp_lwt.Body.to_string body in
  let code = Code.code_of_status (Response.status resp) in
  if code = 200 then (
    Dream.log "File sucessfully pushed !";
    Lwt.return `Success)
  else (
    Dream.log "Error while uploading...";
    Lwt.return `Failure)
