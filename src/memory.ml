open BasicTypes

(* ******************************************************************** *)
(*                      All server memory is here                       *)
(* ******************************************************************** *)

let server =
  {
    pages = StringMap.empty;
    document_list = [];
    sessions = StringMap.empty;
    users = StringMap.empty;
  }

(* ******************************************************************** *)
(*                   Helper functions to interact with memory           *)
(* ******************************************************************** *)

let default_page () =
  {
    id = "error_page";
    name = "Error Page";
    endpoint = "/index";
    markdown = "# Error loading page.\nYou are nowhere...";
  }

let empty_session () =
  {
    messages = [];
    active_page = default_page ();
    connected = false;
    csrf = "this-is-a-false-csrf-token";
  }

let get_page_list () = server.pages |> StringMap.to_seq |> List.of_seq |> List.map snd

let get_session r =
  let id = Dream.session_id r in
  match StringMap.find_opt id server.sessions with
  | Some session -> session
  | None ->
      let new_session = empty_session () in
      server.sessions <- StringMap.add id new_session server.sessions;
      new_session

let reload_page p =
  let* markdown = Storage.get_file `Private (p.id ^ ".md") in
  let markdown =
    match markdown with
    | Ok m -> m
    | Error _ -> "# Erreur, fichier non trouvé\nProblème de connexion avec la base de donnée."
  in
  p.markdown <- markdown;
  Lwt.return ()

let create_page id =
  let p =
    { id; name = id; endpoint = "/" ^ id; markdown = "# Error loading page.\nYou are nowhere..." }
  in
  server.pages <- StringMap.add id p server.pages;
  reload_page p

let get_page id =
  match StringMap.find_opt id server.pages with None -> default_page () | Some p -> p

let reload_users () =
  let* resp = Storage.get_file `Private "users.json" in
  let* str = match resp with Error _ -> failwith "Get Failed" | Ok f -> Lwt.return f in
  let ul = str |> Yojson.Safe.from_string |> user_list_of_yojson in
  List.iter (fun u -> server.users <- StringMap.add u.pseudo u server.users) ul;
  Lwt.return ()

let verify pseudo pwd =
  let user = StringMap.find pseudo server.users in
  let encoded = user.hashed_password in
  match Argon2.verify ~encoded ~pwd ~kind:Argon2.ID with Ok b -> b | Error _ -> false
