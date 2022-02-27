open Cohttp
open Cohttp_lwt_unix

let ( let* ) = Lwt.bind
let sprintf = Format.sprintf

let public_folder_url =
  "https://storage.googleapis.com/erudite-descent-342509-public-bucket/documents/"

let api =
  "https://storage.googleapis.com/storage/v1/b/erudite-descent-342509-public-bucket/o"

let link url text = "<a href=\"" ^ url ^ "\">" ^ text ^ "</a>"

type storage_object = { name : string; mediaLink : string }
[@@deriving yojson, show] [@@yojson.allow_extra_fields]

type object_list = { kind : string; items : storage_object list }
[@@deriving yojson, show]

let test_handler _r =
  let* resp, body = Client.get (Uri.of_string api) in
  let code = Code.code_of_status (Response.status resp) in
  Dream.log "Object list %d" code;
  (* let headers = Header.to_string (Response.headers resp) in *)
  (* Dream.log "Headers %s" headers; *)
  let* json_string = Cohttp_lwt.Body.to_string body in
  (* Dream.log "Body of length: %d\n" (String.length body); *)
  let json_safe = Yojson.Safe.from_string json_string in
  (* Dream.log "Parsed to %a" Yojson.Safe.pp json_safe; *)
  let obj_list = object_list_of_yojson json_safe in
  Dream.log "\n%s" (show_object_list obj_list);
  let s =
    List.map
      (fun obj ->
        sprintf "<li><a href='%s'> %s </a></li>" obj.mediaLink obj.name)
      obj_list.items
    |> String.concat "\n\n"
  in
  Dream.html (sprintf "<ul>%s</ul>" s)

let () =
  Dream.run ~interface:"0.0.0.0" ~port:8080
  @@ Dream.logger
  @@ Dream.router
       [
         Dream.get "/" (fun _ ->
             Dream.html
               ("This was deployed automatically (3) ! <br> "
              ^ link "/test" "Documents"));
         Dream.get "/test" test_handler;
         Dream.get "/static/**" @@ Dream.static "static";
       ]
