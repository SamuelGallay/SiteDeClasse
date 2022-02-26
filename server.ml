let () =
  Dream.run ~interface:"0.0.0.0" ~port:8080
  @@ Dream.logger
  @@ Dream.router
       [
         Dream.get "/" (fun _ -> Dream.html "This was deployed automatically !");
         Dream.get "/static/**" @@ Dream.static "static";
       ]
