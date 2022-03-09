open Cohttp
open Cohttp_lwt_unix
open Json

let sprintf = Format.sprintf
let ( let* ) = Lwt.bind

let get_objects () =
  let api = "https://storage.googleapis.com/storage/v1/b/erudite-descent-342509-public-bucket/o" in
  let* resp, body = Client.get (Uri.of_string api) in
  let code = Code.code_of_status (Response.status resp) in
  Dream.log "Object list %d" code;
  let* json_string = Cohttp_lwt.Body.to_string body in
  let json_safe = Yojson.Safe.from_string json_string in
  let obj_list = Json.object_list_of_yojson json_safe in
  (* Dream.log "\n%s" (show_object_list obj_list); *)
  Lwt.return (List.map (fun o -> (o.name, o.mediaLink)) obj_list.items)

let push_file name content =
  let jwt = Crypto.form_jwt () in
  let* token = Crypto.get_token jwt in
  let url =
    "https://storage.googleapis.com/upload/storage/v1/b/erudite-descent-342509-public-bucket/o"
  in
  let uri = Uri.with_query' (Uri.of_string url) [ ("name", name); ("uploadType", "media") ] in
  let* resp, body =
    Client.post
      ~headers:
        (Header.of_list
           [
             ("Content-Type", Magic_mime.lookup name); ("Authorization", sprintf "Bearer %s" token);
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

let push_and_return_message (name, content) =
  let s = String.length content in
  match name with
  | Some n -> (
      let* res = push_file n content in
      match res with
      | `Failure ->
          Lwt.return
            (sprintf "Échec à la sauvegarde du fichier %s de %i octets dans la base de données." n s)
      | `Success ->
          Lwt.return
            (sprintf "Le fichier %s de %i a été enregistré avec succes dans la base de données." n s)
      )
  | None ->
      Lwt.return
        (sprintf "Ce document ne possède pas de nom et donc n'a pas été envoyé à la base de donnée.")
