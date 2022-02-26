let () =
  Dream.run @@ Dream.logger
  @@ Dream.router
       [
         Dream.get "/" (fun _ -> Dream.html "Samuel");
         Dream.get "/static/**" @@ Dream.static "static";
       ]
