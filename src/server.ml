open BasicTypes

let auth handler r =
  let se = Memory.get_session r in
  if se.connected then handler r
  else Dream.respond ~status:`Unauthorized "Unauthorized (Log in first)"

let routes =
  [
    Dream.get "/" (fun r -> Dream.redirect r "/index");
    Dream.get "/static/**" @@ Dream.static "static";
    Dream.get "/favicon.ico" (Dream.from_filesystem "static" "favicon.ico");
    Dream.get "/login" Handler.login_get;
    Dream.post "/login" Handler.login_post;
    Dream.get "/logout" Handler.logout;
    Dream.get "/documents" @@ auth Handler.documents_page;
    Dream.get "/reload_users" @@ auth Handler.reload_users;
    Dream.post "/upload_documents" @@ auth Handler.push_documents;
    Dream.post "/upload_markdown/:page_id" @@ auth Handler.upload_markdown;
    Dream.get "/edit_markdown/:page_id" @@ auth Handler.edit_markdown;
    Dream.get "/:page_id" Handler.markdown_page;
  ]

let main =
  Mirage_crypto_rng_lwt.initialize (module Mirage_crypto_rng.Fortuna);
  let* () = [ "index"; "cours"; "test" ] |> List.map Memory.create_page |> Lwt.join in
  let* () = Memory.reload_users () in
  let* () = Memory.reload_documents () in
  let* () = Lwt_io.write_line Lwt_io.stdout "Server Started..." in
  Dream.serve ~interface:"0.0.0.0" ~port:8080
  @@ Dream.logger @@ Dream.memory_sessions @@ Dream.router routes

let () = Lwt_main.run main
