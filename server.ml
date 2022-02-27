let () =
  Dream.run ~interface:"0.0.0.0" ~port:8080
  @@ Dream.logger
  @@ Dream.router
       [
         Dream.get "/" (fun _ -> Rendering.index);
         Dream.get "/documents" Handler.documents;
         Dream.get "/static/**" @@ Dream.static "static";
       ]
