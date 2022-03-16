let ( let* ) = Lwt.bind
let s = Memory.server
let sprintf = Format.sprintf

let markdown_page page_id r =
  let se = Memory.get_session r in
  let page = Memory.get_page page_id in
  se.active_page <- page;
  se.csrf <- Dream.csrf_token r;
  Rendering.markdown_page se |> Dream.html

let upload_markdown page_id r =
  let* res = Dream.form r in
  let se = Memory.get_session r in
  match res with
  | `Ok [ ("text", content) ] -> (
      let* result = Storage.push_file `Private (page_id ^ ".md") content in
      match result with
      | Error _ ->
          se.messages <- "Failure to push Markdown" :: se.messages;
          Dream.redirect r se.active_page.endpoint
      | Ok _ ->
          let* () = Memory.reload_page (Memory.get_page page_id) in
          Dream.redirect r se.active_page.endpoint)
  | _ -> Dream.redirect r se.active_page.endpoint

let login_post r =
  let se = Memory.get_session r in
  let* res = Dream.form r in
  match res with
  | `Ok [ ("password", password); ("username", username) ] ->
      se.connected <- Memory.verify username password;
      if not se.connected then Dream.log "Password Error";
      Dream.redirect r se.active_page.endpoint
  | _ ->
      Dream.log "Form Error";
      Dream.redirect r se.active_page.endpoint

let logout r =
  let se = Memory.get_session r in
  se.connected <- false;
  Dream.redirect r se.active_page.endpoint

let login_get r =
  let se = Memory.get_session r in
  se.csrf <- Dream.csrf_token r;
  Rendering.login_page se |> Dream.html

let refresh_documents r =
  let se = Memory.get_session r in
  let* l = Storage.get_file_list `Public in
  match l with
  | Ok l ->
      s.document_list <- l;
      Dream.redirect r se.active_page.endpoint
  | Error _ -> Dream.redirect r se.active_page.endpoint

let refresh_users r =
  let se = Memory.get_session r in
  let* () = Memory.reload_users () in
  Dream.redirect r se.active_page.endpoint

let push_if_file_is_named (name, content) =
  let l = String.length content in
  match name with
  | None ->
      Lwt.return
        (sprintf "Ce document ne possède pas de nom et donc n'a pas été envoyé à la base de donnée.")
  | Some n -> (
      let* res = Storage.push_file `Public n content in
      match res with
      | Error _ ->
          Lwt.return
            (sprintf "Échec à la sauvegarde du fichier %s de %i octets dans la base de données." n l)
      | Ok _ ->
          Lwt.return
            (sprintf "Le fichier %s de %i a été enregistré avec succes dans la base de données." n l)
      )

let push_documents r =
  let* res = Dream.multipart r in
  let se = Memory.get_session r in
  match res with
  | `Ok [ ("file", files) ] ->
      let* messages = files |> List.map push_if_file_is_named |> Lwt.all in
      se.messages <- messages @ se.messages;
      if messages = [] then se.messages <- "No file selected" :: se.messages;
      Dream.redirect r se.active_page.endpoint
  | _ ->
      se.messages <- "Error in Request" :: se.messages;
      Dream.redirect r se.active_page.endpoint
