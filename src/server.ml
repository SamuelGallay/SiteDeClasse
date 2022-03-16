open BasicTypes

let main =
  let () = Mirage_crypto_rng_lwt.initialize () in
  let* () = [ "index"; "cours"; "test" ] |> List.map Memory.create_page |> Lwt.join in
  let* () = Memory.reload_users () in
  let* () = Lwt_io.write_line Lwt_io.stdout "Server Started..." in
  Dream.serve ~interface:"0.0.0.0" ~port:8080
  @@ Dream.logger @@ Dream.memory_sessions
  @@ Dream.router
       ([
          Dream.get "/" (Handler.markdown_page "index");
          Dream.post "/refresh_documents" Handler.refresh_documents;
          Dream.get "/refresh_users" Handler.refresh_users;
          Dream.get "/static/**" @@ Dream.static "static";
          Dream.post "/upload_documents" Handler.push_documents;
          Dream.get "/favicon.ico" (Dream.from_filesystem "static" "favicon.ico");
          Dream.get "/login" Handler.login_get;
          Dream.get "/logout" Handler.logout;
          Dream.post "/login" Handler.login_post;
        ]
       @ List.map (fun p -> Dream.get p.id (Handler.markdown_page p.id)) (Memory.get_page_list ())
       @ List.map
           (fun p -> Dream.post ("upload_markdown/" ^ p.id) (Handler.upload_markdown p.id))
           (Memory.get_page_list ()))

let () = Lwt_main.run main
