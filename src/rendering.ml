open Tyxml.Html
open BasicTypes

let s = Memory.server
let sprintf = Format.sprintf
let html_to_string html = Format.asprintf "%a" (Tyxml.Html.pp ()) html
let empty_div = div ~a:[] []

(* ******************************************************************** *)
(*                         Html Head and Nav                            *)
(* ******************************************************************** *)

let html_head =
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

let menu_nav se =
  let page_links = List.map (fun n -> li [ a ~a:[ a_href ("/" ^ n) ] [ txt n ] ]) s.page_list in
  let connect_li =
    li
      ~a:[ a_style "float:right" ]
      [
        a
          ~a:[ a_class [ "active" ]; a_href "/connect" ]
          [ txt (if se.connected then "Se déconnecter" else "Se connecter") ];
      ]
  in
  nav ~a:[] [ ul (page_links @ [ connect_li ]) ]

(* ******************************************************************** *)
(*                        Documents                                     *)
(* ******************************************************************** *)

let upload_documents_div csrf_token =
  div
    ~a:[ a_class [ "full-width" ] ]
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

let refresh_documents_form csrf =
  form
    ~a:[ a_action "/refresh_documents"; a_method `Post ]
    [
      input ~a:[ a_input_type `Hidden; a_name "dream.csrf"; a_value csrf ] ();
      button ~a:[ a_button_type `Submit ] [ txt "Refresh" ];
    ]

let document_list_div se =
  let f (name, link) = li [ a ~a:[ a_href link ] [ txt name ] ] in
  div
    ~a:[ a_class [ "menu"; "full-width" ] ]
    [ ul (List.map f s.document_list); refresh_documents_form se.csrf ]

let documents_div se =
  if se.connected then
    div ~a:[ a_class [ "full-width" ] ] [ document_list_div se; upload_documents_div se.csrf ]
  else empty_div

(* ******************************************************************** *)
(*                        Messages                                      *)
(* ******************************************************************** *)

let messages_div se =
  let f x = li [ txt x ] in
  if not se.connected then empty_div
  else
    div
      ~a:[ a_class [ "orange-msg"; "full-width" ] ]
      [ txt "Messages :"; ul (List.map f se.messages) ]

(* ******************************************************************** *)
(*                        Markdown                                      *)
(* ******************************************************************** *)

let input_markdown_form markdown se =
  if not se.connected then empty_div
  else
    form
      ~a:[ a_action ("/upload_markdown/" ^ se.active_page); a_method `Post ]
      [
        input ~a:[ a_input_type `Hidden; a_name "dream.csrf"; a_value se.csrf ] ();
        textarea ~a:[ a_name "text" ] (txt markdown);
        button ~a:[ a_button_type `Submit ] [ txt "Mettre à jour" ];
      ]

let html_of_markdown m = m |> Omd.of_string |> Omd.to_html |> Unsafe.data

(* ******************************************************************** *)
(*                        General Layout                                *)
(* ******************************************************************** *)

let index se markdown =
  html html_head
    (body
       [
         header
           ~a:[ a_class [ "row" ] ]
           [ h1 [ txt "ENS Rennes - Promotion 2021 - Mathématiques" ] ];
         menu_nav se;
         div
           ~a:[ a_class [ "row" ] ]
           [
             div ~a:[ a_class [ "col-2" ] ] [ messages_div se ];
             div
               ~a:[ a_class [ "col-8" ] ]
               [ html_of_markdown markdown; input_markdown_form markdown se ];
             div ~a:[ a_class [ "col-2" ] ] [ documents_div se ];
           ];
       ])
  |> html_to_string
