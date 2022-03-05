open Tyxml.Html

let sprintf = Format.sprintf
let html_to_string html = Format.asprintf "%a" (Tyxml.Html.pp ()) html

let index csrf_token =
  html
    (head
       (title (txt "Titre"))
       [
         link ~rel:[ `Stylesheet ] ~href:"static/mystyle.css" ~a:[] ();
         meta ~a:[ a_name "viewport"; a_content "width=device-width, initial-scale=1.0" ] ();
       ])
    (body
       [
         div ~a:[ a_class [ "row" ] ] [ div ~a:[ a_class [ "header" ] ] [ h1 [ txt "Main Title" ] ] ];
         (* txt "This was deployed automatically (3) !"; *)
         (* br (); *)
         div
           ~a:[ a_class [ "row" ] ]
           [
             div ~a:[ a_class [ "col-2"; "menu" ] ] [ ul [ li [ a ~a:[ a_href "/documents" ] [ txt "Documents" ] ] ] ];
             div ~a:[ a_class [ "col-7" ] ] [];
             div
               ~a:[ a_class [ "col-3" ] ]
               [
                 form
                   ~a:[ a_action "/form"; a_method `Post; a_enctype "multipart/form-data" ]
                   [
                     txt "Formulaire :";
                     input ~a:[ a_input_type `Hidden; a_name "dream.csrf"; a_value csrf_token ] ();
                     input ~a:[ a_input_type `File; a_name "file" ] ();
                     button ~a:[ a_button_type `Submit ] [ txt "Submit" ];
                   ];
               ];
           ];
       ])
  |> html_to_string |> Dream.html

let documents l =
  let f (name, link) = li [ a ~a:[ a_href link ] [ txt name ] ] in
  html (head (title (txt "Titre")) []) (body [ ul (List.map f l) ]) |> html_to_string |> Dream.html

let files files =
  let string_of_status = function
    | `Not_Pushed -> "File wasn't pushed to the database."
    | `Success -> "File was successfully pushed to the database."
    | `Failure -> "File failed to be pushed to the database."
  in
  let f (name, length, status) = li [ txt (sprintf "File has name '%s' and is of size %i. %s" name length (string_of_status status)) ] in
  html (head (title (txt "Titre")) []) (body [ ul (List.map f files) ]) |> html_to_string |> Dream.html
