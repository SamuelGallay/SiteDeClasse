let ( let* ) = Lwt.bind
let s = Memory.server

let markdown_page filename r =
  let se = Memory.get_session r in
  se.active_page <- filename;
  let* markdown = Storage.get_file `Private (filename ^ ".md") in
  let markdown =
    match markdown with
    | Some m -> m
    | None -> "# Erreur, fichier non trouvé\nProblème de connexion avec la base de donnée."
  in
  Rendering.index (Dream.csrf_token r) (Memory.get_session r) markdown |> Dream.html

let refresh_documents r =
  let se = Memory.get_session r in
  let* l = Storage.get_file_list `Public in
  Dream.log "Updated Documents !";
  s.document_list <- l;
  Dream.redirect r se.active_page

let push_documents r =
  let* res = Dream.multipart r in
  let se = Memory.get_session r in
  match res with
  | `Ok [ ("file", files) ] ->
      let* messages = files |> List.map Storage.push_if_file_is_named |> Lwt.all in
      se.messages <- messages @ se.messages;
      if messages = [] then se.messages <- "No file selected" :: se.messages;
      Dream.redirect r se.active_page
  | _ ->
      se.messages <- "Error in Request" :: se.messages;
      Dream.redirect r se.active_page

let upload_markdown name r =
  let* res = Dream.form r in
  let se = Memory.get_session r in
  match res with
  | `Ok [ ("text", content) ] ->
      let* result = Storage.push_file `Private (name ^ ".md") content in
      if result = `Failure then se.messages <- "Failure to push Markdown" :: se.messages;
      Dream.redirect r se.active_page
  | _ -> Dream.redirect r se.active_page
