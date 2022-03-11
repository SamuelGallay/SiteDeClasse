let s = Memory.server

let () =
  Dream.run ~interface:"0.0.0.0" ~port:8080
  @@ (fun x ->
       Mirage_crypto_rng_lwt.initialize ();
       x)
  @@ Dream.logger @@ Dream.memory_sessions
  @@ Dream.router
       ([
          Dream.get "/" (Handler.markdown_page "index");
          Dream.post "/refresh_documents" Handler.refresh_documents;
          Dream.get "/static/**" @@ Dream.static "static";
          Dream.post "/upload_documents" Handler.push_documents;
          Dream.get "/favicon.ico" (Dream.from_filesystem "static" "favicon.ico");
        ]
       @ List.map (fun n -> Dream.get n (Handler.markdown_page n)) s.page_list
       @ List.map
           (fun n -> Dream.post ("upload_markdown/" ^ n) (Handler.upload_markdown n))
           s.page_list)
