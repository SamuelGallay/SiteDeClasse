let ( let* ) = Lwt.bind

let markdown_page filename r =
  let* markdown = Storage.get_file `Private (filename ^ ".md") in
  let markdown =
    match markdown with
    | Some m -> m
    | None -> "# Erreur, fichier non trouvé\nProblème de connexion avec la base de donnée."
  in
  Rendering.index (Dream.csrf_token r) (Dream.session_id r) markdown filename |> Dream.html

let refresh_documents r =
  let* l = Storage.get_file_list `Public in
  Dream.log "Updated Documents !";
  State.documents := Some l;
  Dream.redirect r "/"

let push_documents r =
  let* res = Dream.multipart r in
  let id = Dream.session_id r in
  match res with
  | `Ok [ ("file", files) ] ->
      let* messages = files |> List.map Storage.push_if_file_is_named |> Lwt.all in
      List.iter (State.add_message id) messages;
      if messages = [] then State.add_message id "No file selected";
      Dream.redirect r "/"
  | _ ->
      State.add_message id "Error in Request";
      Dream.redirect r "/"

let upload_markdown name r =
  let* res = Dream.form r in
  let id = Dream.session_id r in
  match res with
  | `Ok [ ("text", content) ] ->
      let* result = Storage.push_file `Private (name ^ ".md") content in
      if result = `Failure then State.add_message id "Failure to push Markdown";
      Dream.redirect r ("/" ^ name)
  | _ -> Dream.redirect r ("/" ^ name)
