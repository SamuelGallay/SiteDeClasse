open Cohttp
open Cohttp_lwt_unix
open Json

let sprintf = Format.sprintf
let ( let* ) = Lwt.bind

let url = function
  | `Private ->
      Uri.of_string
        "https://storage.googleapis.com/storage/v1/b/erudite-descent-342509-private-bucket/o"
  | `Public ->
      Uri.of_string
        "https://storage.googleapis.com/storage/v1/b/erudite-descent-342509-public-bucket/o"

let get_file_list bucket =
  let* resp, body = Client.get (url bucket) in
  let code = Code.code_of_status (Response.status resp) in
  Dream.log "Object list %d" code;
  let* json_string = Cohttp_lwt.Body.to_string body in
  let json_safe = Yojson.Safe.from_string json_string in
  let obj_list = Json.object_list_of_yojson json_safe in
  Lwt.return (List.map (fun o -> (o.name, o.mediaLink)) obj_list.items)

let push_file bucket name content =
  let* token = State.get_token () in
  let uri = Uri.with_query' (url bucket) [ ("name", name); ("uploadType", "media") ] in
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
  if code = 200 then Lwt.return `Success else Lwt.return `Failure

let push_if_file_is_named (name, content) =
  let l = String.length content in
  match name with
  | None ->
      Lwt.return
        (sprintf "Ce document ne possède pas de nom et donc n'a pas été envoyé à la base de donnée.")
  | Some n -> (
      let* res = push_file `Public n content in
      match res with
      | `Failure ->
          Lwt.return
            (sprintf "Échec à la sauvegarde du fichier %s de %i octets dans la base de données." n l)
      | `Success ->
          Lwt.return
            (sprintf "Le fichier %s de %i a été enregistré avec succes dans la base de données." n l)
      )
