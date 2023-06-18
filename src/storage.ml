open Cohttp
open Cohttp_lwt_unix
open BasicTypes

let sprintf = Format.sprintf
let ( let* ) = Lwt.bind

let get_token =
  let token : token option ref = ref None in
  let update_token () =
    let* tok = Crypto.get_token () in
    token := Some tok;
    Lwt.return tok.token
  in
  fun () ->
    match !token with
    | None -> update_token ()
    | Some tok -> if Unix.time () < tok.expiration then Lwt.return tok.token else update_token ()

let url ?(obj = "") = function
  | `Private ->
      Uri.of_string
        ("https://storage.googleapis.com/storage/v1/b/erudite-descent-342509-private-bucket/o/"
       ^ obj)
  | `Public ->
      Uri.of_string
        ("https://storage.googleapis.com/storage/v1/b/erudite-descent-342509-public-bucket/o/" ^ obj)

let upload_url = function
  | `Private ->
      Uri.of_string
        "https://storage.googleapis.com/upload/storage/v1/b/erudite-descent-342509-private-bucket/o"
  | `Public ->
      Uri.of_string
        "https://storage.googleapis.com/upload/storage/v1/b/erudite-descent-342509-public-bucket/o"

let get_file_list bucket =
  let* resp, body = Client.get (url bucket) in
  let* body_string = Cohttp_lwt.Body.to_string body in
  let code = Code.code_of_status (Response.status resp) in
  if code != 200 then Lwt.return (Error body_string)
  else
    let json_safe = Yojson.Safe.from_string body_string in
    let obj_list = object_list_of_yojson json_safe in
    let file_list = List.map (fun (o : storage_object) -> (o.name, o.mediaLink)) obj_list.items in
    Lwt.return (Ok file_list)

let get_file _bucket name =
  let* f = Lwt_io.open_file ~mode:Lwt_io.Input ("storage/" ^ name) in
  let* s = Lwt_io.read f in
  Lwt.return (Ok s)

let get_file_fancy bucket name =
  let* token = get_token () in
  let uri = Uri.with_query' (url ~obj:name bucket) [ ("alt", "media") ] in
  let* resp, body =
    Client.get uri ~headers:(Header.of_list [ ("Authorization", sprintf "Bearer %s" token) ])
  in
  let* body_string = Cohttp_lwt.Body.to_string body in
  let code = Code.code_of_status (Response.status resp) in
  if code = 200 then Lwt.return (Ok body_string) else Lwt.return (Error body_string)

let push_file _bucket name content =
  let* f = Lwt_io.open_file ~mode:Lwt_io.Output ("storage/" ^ name) in
  let* s = Lwt_io.write f content in
  Lwt.return (Ok s)

let push_file_fancy bucket name content =
  let* token = get_token () in
  let uri = Uri.with_query' (upload_url bucket) [ ("name", name); ("uploadType", "media") ] in
  let* resp, body =
    Client.post
      ~headers:
        (Header.of_list
           [
             ("Content-Type", Magic_mime.lookup name); ("Authorization", sprintf "Bearer %s" token);
           ])
      ~body:(`String content) uri
  in
  let* body_string = Cohttp_lwt.Body.to_string body in
  let code = Code.code_of_status (Response.status resp) in
  if code = 200 then Lwt.return (Ok ()) else Lwt.return (Error body_string)
