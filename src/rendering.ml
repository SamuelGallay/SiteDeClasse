open Tyxml.Html
open BasicTypes

let s = Memory.server
let sprintf = Format.sprintf
let html_to_string html = Format.asprintf "%a" (Tyxml.Html.pp ()) html

(* ******************************************************************** *)
(*                         Html Head and Nav                            *)
(* ******************************************************************** *)

let html_head =
  head
    (title (txt "Site de Classe"))
    [
      meta ~a:[ a_name "viewport"; a_content "width=device-width, initial-scale=1.0" ] ();
      link ~rel:[ `Stylesheet ] ~href:"/static/mystyle.css" ~a:[] ();
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
  let page_list = Memory.get_page_list () in
  let page_links = List.map (fun p -> li [ a ~a:[ a_href p.endpoint ] [ txt p.name ] ]) page_list in
  let connect_li =
    li
      ~a:[ a_style "float:right" ]
      [
        (if not se.connected then
         a ~a:[ a_class [ "connect" ]; a_href "/login" ] [ txt "Se connecter" ]
        else a ~a:[ a_class [ "disconnect" ]; a_href "/logout" ] [ txt "Se déconnecter" ]);
      ]
  in
  nav ~a:[] [ ul (page_links @ [ connect_li ]) ]

(* ******************************************************************** *)
(*                        Messages                                      *)
(* ******************************************************************** *)

let messages_div se =
  let f x = li [ txt x ] in
  div
    ~a:[ a_class [ "orange-msg"; "full-width" ] ]
    [ txt "Messages :"; ul (List.map f se.messages) ]

(* ******************************************************************** *)
(*                        Actions Menu                                  *)
(* ******************************************************************** *)

let documents_action = div ~a:[] [ a ~a:[ a_href "/documents" ] [ txt "Liste des documents" ] ]

let edit_action se =
  div ~a:[] [ a ~a:[ a_href ("/edit_markdown/" ^ se.active_page.id) ] [ txt "Éditer la page" ] ]

(* ******************************************************************** *)
(*                        Markdown Page                                 *)
(* ******************************************************************** *)

let input_markdown_form se =
  form
    ~a:[ a_action ("/upload_markdown/" ^ se.active_page.id); a_method `Post ]
    [
      input ~a:[ a_input_type `Hidden; a_name "dream.csrf"; a_value se.csrf ] ();
      textarea ~a:[ a_name "text" ] (txt se.active_page.markdown);
      button ~a:[ a_button_type `Submit ] [ txt "Mettre à jour" ];
    ]

let html_of_markdown m = m |> Omd.of_string |> Omd.to_html |> Unsafe.data

let markdown_page se =
  html html_head
    (body
       [
         header ~a:[ a_class [] ] [ h1 [ txt "ENS Rennes - Promotion 2021 - Mathématiques" ] ];
         menu_nav se;
         div
           ~a:[ a_class [] ]
           [
             div
               ~a:[ a_class [ "col-2" ] ]
               (if se.connected then [ edit_action se; documents_action ] else []);
             div ~a:[ a_class [ "col-8" ] ] [ html_of_markdown se.active_page.markdown ];
             div ~a:[ a_class [ "col-2" ] ] [];
           ];
       ])
  |> html_to_string

(* ******************************************************************** *)
(*                        Login Page                                    *)
(* ******************************************************************** *)

let login_form se =
  form
    ~a:[ a_action "/login"; a_method `Post ]
    [
      input ~a:[ a_input_type `Hidden; a_name "dream.csrf"; a_value se.csrf ] ();
      h1 [ txt "Connexion" ];
      div ~a:[]
        [
          label ~a:[ a_label_for "username" ] [ txt "Nom d'utilisateur : " ];
          input ~a:[ a_input_type `Text; a_name "username" ] ();
        ];
      div ~a:[]
        [
          label ~a:[ a_label_for "password" ] [ txt "Mot de passe : " ];
          input ~a:[ a_input_type `Password; a_name "password" ] ();
        ];
      button ~a:[ a_button_type `Submit ] [ txt "Connexion" ];
    ]

let login_page se =
  html html_head
    (body
       [
         header ~a:[ a_class [] ] [ h1 [ txt "ENS Rennes - Promotion 2021 - Mathématiques" ] ];
         div
           ~a:[ a_class [] ]
           [
             div ~a:[ a_class [ "col-2" ] ] [];
             div ~a:[ a_class [ "col-8" ] ] [ login_form se ];
             div ~a:[ a_class [ "col-2" ] ] [];
           ];
       ])
  |> html_to_string

(* ******************************************************************** *)
(*                        Documents Page                                *)
(* ******************************************************************** *)

let upload_documents_div csrf_token =
  div
    ~a:[ a_class [ "full-width" ] ]
    [
      form
        ~a:[ a_action "/upload_documents"; a_method `Post; a_enctype "multipart/form-data" ]
        [
          input ~a:[ a_input_type `Hidden; a_name "dream.csrf"; a_value csrf_token ] ();
          label ~a:[ a_class [] ] [ input ~a:[ a_input_type `File; a_name "file" ] () ];
          button ~a:[ a_button_type `Submit ] [ txt "Envoyer le document" ];
        ];
    ]

let document_list_div _se =
  let f (name, link) = li [ a ~a:[ a_href link ] [ txt name ] ] in
  div ~a:[ a_class [ "full-width" ] ] [ ul (List.map f s.document_list) ]

let documents_page se =
  html html_head
    (body
       [
         header ~a:[ a_class [] ] [ h1 [ txt "ENS Rennes - Promotion 2021 - Mathématiques" ] ];
         menu_nav se;
         div
           ~a:[ a_class [] ]
           [
             div ~a:[ a_class [ "col-2" ] ] [];
             div
               ~a:[ a_class [ "col-8" ] ]
               [
                 h1 [ txt "Liste des documents" ];
                 document_list_div se;
                 h1 [ txt "Ajouter un document" ];
                 upload_documents_div se.csrf;
               ];
             div ~a:[ a_class [ "col-2" ] ] [];
           ];
       ])
  |> html_to_string

(* ******************************************************************** *)
(*                        Edit markdown page                            *)
(* ******************************************************************** *)

let edit_page se =
  html html_head
    (body
       [
         header ~a:[ a_class [] ] [ h1 [ txt "ENS Rennes - Promotion 2021 - Mathématiques" ] ];
         menu_nav se;
         div
           ~a:[ a_class [] ]
           [
             div ~a:[ a_class [ "col-2" ] ] [];
             div ~a:[ a_class [ "col-8" ] ] [ input_markdown_form se ];
             div ~a:[ a_class [ "col-2" ] ] [];
           ];
       ])
  |> html_to_string
