let () =
  Dream.run ~interface:"0.0.0.0" ~port:8080
  @@ (fun x ->
       Mirage_crypto_rng_lwt.initialize ();
       x)
  @@ Dream.logger @@ Dream.memory_sessions
  @@ Dream.router
       [
         Dream.get "/" Handler.main;
         Dream.post "/refresh_documents" Handler.refresh_documents;
         Dream.get "/static/**" @@ Dream.static "static";
         Dream.post "/form" Handler.form;
         Dream.get "/favicon.ico" (Dream.from_filesystem "static" "favicon.ico");
         Dream.post "/upload" Handler.upload;
       ]
