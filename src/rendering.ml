open Tyxml.Html

let sprintf = Format.sprintf
let html_to_string html = Format.asprintf "%a" (Tyxml.Html.pp ()) html

let header_elt =
  head
    (title (txt "Titre 2"))
    [
      link ~rel:[ `Stylesheet ] ~href:"static/mystyle.css" ~a:[] ();
      meta ~a:[ a_name "viewport"; a_content "width=device-width, initial-scale=1.0" ] ();
    ]

let form_elt csrf_token =
  div
    ~a:[ a_class [ "col-12" ] ]
    [
      form
        ~a:[ a_action "/form"; a_method `Post; a_enctype "multipart/form-data" ]
        [
          input ~a:[ a_input_type `Hidden; a_name "dream.csrf"; a_value csrf_token ] ();
          label
            ~a:[ a_class [ "custom-file-upload" ] ]
            [ input ~a:[ a_input_type `File; a_name "file" ] () ];
          button ~a:[ a_button_type `Submit ] [ txt "Submit" ];
        ];
    ]

let refresh csrf =
  form
    ~a:[ a_action "/refresh_documents"; a_method `Post ]
    [
      input ~a:[ a_input_type `Hidden; a_name "dream.csrf"; a_value csrf ] ();
      button ~a:[ a_button_type `Submit ] [ txt "Refresh" ];
    ]

let doc_elt csrf =
  match !State.documents with
  | None -> [ refresh csrf ]
  | Some l ->
      let f (name, link) = li [ a ~a:[ a_href link ] [ txt name ] ] in
      [ ul (List.map f l); refresh csrf ]

let msg_elt id =
  let msg = State.get_messages id in
  let f x = li [ txt x ] in
  div ~a:[ a_class [ "orange-msg"; "col-12" ] ] [ txt "Messages :"; ul (List.map f msg) ]

let text_elt csrf =
  form
    ~a:[ a_action "/upload"; a_method `Post ]
    [
      input ~a:[ a_input_type `Hidden; a_name "dream.csrf"; a_value csrf ] ();
      textarea ~a:[ a_name "text" ] (txt !State.test);
      button ~a:[ a_button_type `Submit ] [ txt "Mettre à jour" ];
    ]

let content () = !State.test |> Omd.of_string |> Omd.to_html |> Unsafe.data
let menu_nav = nav ~a:[] [ ul [ li [ txt "Hello" ] ] ]

let index csrf id =
  html header_elt
    (body
       [
         header ~a:[ a_class [ "row" ] ] [ h1 [ txt "Main Title" ] ];
         menu_nav;
         div
           ~a:[ a_class [ "row" ] ]
           [
             div ~a:[ a_class [ "col-2"; "menu" ] ] (doc_elt csrf);
             div ~a:[ a_class [ "col-8" ] ] [ content (); text_elt csrf ];
             div ~a:[ a_class [ "col-2" ] ] [ form_elt csrf; msg_elt id ];
           ];
       ])
  |> html_to_string
