open Tyxml
open Html
open Format

let html_to_string html = Format.asprintf "%a" (Tyxml.Html.pp ()) html

let index csrf_token =
  html
    (head (title (txt "Titre")) [])
    (body
       [
         txt "This was deployed automatically (3) !";
         br ();
         a ~a:[ a_href "/documents" ] [ txt "Documents" ];
         form
           ~a:
             [
               a_action "/form"; a_method `Post; a_enctype "multipart/form-data";
             ]
           [
             txt "Formulaire :";
             input
               ~a:
                 [
                   a_input_type `Hidden; a_name "dream.csrf"; a_value csrf_token;
                 ]
               ();
             input ~a:[ a_input_type `File; a_name "file" ] ();
             button ~a:[ a_button_type `Submit ] [ txt "Submit" ];
           ];
       ])
  |> html_to_string |> Dream.html

let documents l =
  let f (name, link) = li [ a ~a:[ a_href link ] [ txt name ] ] in
  html (head (title (txt "Titre")) []) (body [ ul (List.map f l) ])
  |> html_to_string |> Dream.html

let files files =
  let string_of_status = function
    | `Not_Pushed -> "File wasn't pushed to the database."
    | `Success -> "File was successfully pushed to the database."
    | `Failure -> "File failed to be pushed to the database."
  in
  let f (name, length, status) =
    li
      [
        txt
          (sprintf "File has name '%s' and is of size %i. %s" name length
             (string_of_status status));
      ]
  in
  html (head (title (txt "Titre")) []) (body [ ul (List.map f files) ])
  |> html_to_string |> Dream.html