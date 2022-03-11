open Tyxml.Html
open BasicTypes

let s = Memory.server
let sprintf = Format.sprintf
let html_to_string html = Format.asprintf "%a" (Tyxml.Html.pp ()) html

let header_elt =
  head
    (title (txt "Site de Classe"))
    [
      meta ~a:[ a_name "viewport"; a_content "width=device-width, initial-scale=1.0" ] ();
      link ~rel:[ `Stylesheet ] ~href:"static/mystyle.css" ~a:[] ();
      link
        ~rel:[ `Stylesheet ]
        ~href:"https://cdn.jsdelivr.net/npm/katex@0.15.2/dist/katex.min.css" ~a:[] ();
      script
        ~a:[ a_defer (); a_src "https://cdn.jsdelivr.net/npm/katex@0.15.2/dist/katex.min.js" ]
        (txt "");
      script
        ~a:
          [
            a_defer ();
            a_src "https://cdn.jsdelivr.net/npm/katex@0.15.2/dist/contrib/auto-render.min.js";
            a_onload "renderMathInElement(document.body);";
          ]
        (txt "");
    ]

let form_elt csrf_token =
  div
    ~a:[ a_class [ "col-12" ] ]
    [
      form
        ~a:[ a_action "/upload_documents"; a_method `Post; a_enctype "multipart/form-data" ]
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
  let f (name, link) = li [ a ~a:[ a_href link ] [ txt name ] ] in
  [ ul (List.map f s.document_list); refresh csrf ]

let msg_elt msg =
  let f x = li [ txt x ] in
  div ~a:[ a_class [ "orange-msg"; "col-12" ] ] [ txt "Messages :"; ul (List.map f msg) ]

let text_elt markdown csrf name =
  form
    ~a:[ a_action ("/upload_markdown/" ^ name); a_method `Post ]
    [
      input ~a:[ a_input_type `Hidden; a_name "dream.csrf"; a_value csrf ] ();
      textarea ~a:[ a_name "text" ] (txt markdown);
      button ~a:[ a_button_type `Submit ] [ txt "Mettre à jour" ];
    ]

let html_of_markdown m = m |> Omd.of_string |> Omd.to_html |> Unsafe.data

let menu_nav =
  let page_links = List.map (fun n -> li [ a ~a:[ a_href ("/" ^ n) ] [ txt n ] ]) s.page_list in
  let connect_li =
    li
      ~a:[ a_style "float:right" ]
      [ a ~a:[ a_class [ "active" ]; a_href "/connect" ] [ txt "Se connecter" ] ]
  in
  nav ~a:[] [ ul (page_links @ [ connect_li ]) ]

let index csrf se markdown =
  html header_elt
    (body
       [
         header
           ~a:[ a_class [ "row" ] ]
           [ h1 [ txt "ENS Rennes - Promotion 2021 - Mathématiques" ] ];
         menu_nav;
         div
           ~a:[ a_class [ "row" ] ]
           [
             div ~a:[ a_class [ "col-2"; "menu" ] ] (doc_elt csrf);
             div
               ~a:[ a_class [ "col-8" ] ]
               [ html_of_markdown markdown; text_elt markdown csrf se.active_page ];
             div ~a:[ a_class [ "col-2" ] ] [ form_elt csrf; msg_elt se.messages ];
           ];
       ])
  |> html_to_string
