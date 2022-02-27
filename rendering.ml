open Tyxml
open Html

let html_to_string html = Format.asprintf "%a" (Tyxml.Html.pp ()) html

let index () =
  html
    (head (title (txt "Titre")) [])
    (body
       [
         txt "This was deployed automatically (3) !";
         br ();
         a ~a:[ a_href "/documents" ] [ txt "Documents" ];
       ])
  |> html_to_string |> Dream.html

let f (name, link) = li [ a ~a:[ a_href link ] [ txt name ] ]

let documents l =
  html (head (title (txt "Titre")) []) (body [ ul (List.map f l) ])
  |> html_to_string |> Dream.html
