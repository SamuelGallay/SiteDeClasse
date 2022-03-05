open Tyxml.Html

let sprintf = Format.sprintf
let html_to_string html = Format.asprintf "%a" (Tyxml.Html.pp ()) html

let header_elt =
  head
    (title (txt "Titre"))
    [
      link ~rel:[ `Stylesheet ] ~href:"static/mystyle.css" ~a:[] ();
      meta ~a:[ a_name "viewport"; a_content "width=device-width, initial-scale=1.0" ] ();
    ]

let form_elt csrf_token =
  form
    ~a:[ a_action "/form"; a_method `Post; a_enctype "multipart/form-data" ]
    [
      input ~a:[ a_input_type `Hidden; a_name "dream.csrf"; a_value csrf_token ] ();
      label ~a:[ a_class [ "custom-file-upload" ] ] [ input ~a:[ a_input_type `File; a_name "file" ] () ];
      button ~a:[ a_button_type `Submit ] [ txt "Submit" ];
    ]

let refresh csrf =
  form
    ~a:[ a_action "/refresh_documents"; a_method `Post ]
    [ input ~a:[ a_input_type `Hidden; a_name "dream.csrf"; a_value csrf ] (); button ~a:[ a_button_type `Submit ] [ txt "Refresh" ] ]

let doc_elt csrf =
  match !State.documents with
  | None -> [ refresh csrf ]
  | Some l ->
      let f (name, link) = li [ a ~a:[ a_href link ] [ txt name ] ] in
      [ ul (List.map f l); refresh csrf ]

let index csrf_token =
  html header_elt
    (body
       [
         div ~a:[ a_class [ "row"; "header" ] ] [ h1 [ txt "Main Title" ] ];
         div
           ~a:[ a_class [ "row" ] ]
           [
             div ~a:[ a_class [ "col-2"; "menu" ] ] (doc_elt csrf_token);
             div ~a:[ a_class [ "col-8" ] ] [ State.content ];
             div ~a:[ a_class [ "col-2" ] ] [ form_elt csrf_token ];
           ];
       ])
  |> html_to_string |> Dream.html

let files files =
  let string_of_status = function
    | `Not_Pushed -> "File wasn't pushed to the database."
    | `Success -> "File was successfully pushed to the database."
    | `Failure -> "File failed to be pushed to the database."
  in
  let f (name, length, status) = li [ txt (sprintf "File has name '%s' and is of size %i. %s" name length (string_of_status status)) ] in
  html (head (title (txt "Titre")) []) (body [ ul (List.map f files) ]) |> html_to_string |> Dream.html
