let ( let* ) = Lwt.bind
let s = Memory.server

let markdown_page page_id r =
  let se = Memory.get_session r in
  let page = Memory.get_page page_id in
  se.active_page <- page;
  se.csrf <- Dream.csrf_token r;
  Rendering.markdown_page se |> Dream.html

let refresh_documents r =
  let se = Memory.get_session r in
  let* l = Storage.get_file_list `Public in
  Dream.log "Updated Documents !";
  s.document_list <- l;
  Dream.redirect r se.active_page.endpoint

let push_documents r =
  let* res = Dream.multipart r in
  let se = Memory.get_session r in
  match res with
  | `Ok [ ("file", files) ] ->
      let* messages = files |> List.map Storage.push_if_file_is_named |> Lwt.all in
      se.messages <- messages @ se.messages;
      if messages = [] then se.messages <- "No file selected" :: se.messages;
      Dream.redirect r se.active_page.endpoint
  | _ ->
      se.messages <- "Error in Request" :: se.messages;
      Dream.redirect r se.active_page.endpoint

let upload_markdown page_id r =
  let* res = Dream.form r in
  let se = Memory.get_session r in
  match res with
  | `Ok [ ("text", content) ] ->
      let* result = Storage.push_file `Private (page_id ^ ".md") content in
      if result = `Failure then se.messages <- "Failure to push Markdown" :: se.messages;
      let* () = Memory.reload_page (Memory.get_page page_id) in
      Dream.redirect r se.active_page.endpoint
  | _ -> Dream.redirect r se.active_page.endpoint

let connect r =
  let se = Memory.get_session r in
  se.connected <- not se.connected;
  Dream.redirect r se.active_page.endpoint
