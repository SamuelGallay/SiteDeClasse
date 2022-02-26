let public_folder_url =
  "https://storage.googleapis.com/erudite-descent-342509-public-bucket/documents/"

let link filename text =
  "<a href=\"" ^ public_folder_url ^ filename ^ "\">" ^ text ^ "</a>"

let () =
  Dream.run ~interface:"0.0.0.0" ~port:8080
  @@ Dream.logger
  @@ Dream.router
       [
         Dream.get "/" (fun _ ->
             Dream.html
               ("This was deployed automatically (3) ! "
               ^ link "rapport.pdf" "Rapport"));
         Dream.get "/static/**" @@ Dream.static "static";
       ]
