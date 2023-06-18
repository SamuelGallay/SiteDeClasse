open Tyxml;
open BasicTypes;

let s = Memory.server;
let sprintf = Format.sprintf;
let html_to_string = html => Format.asprintf("%a", Tyxml.Html.pp(), html);

/* ******************************************************************** */
/*                         Html Head and Nav                            */
/* ******************************************************************** */

let html_head =
  <head>
    <title> "Site de Classe" </title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <link rel=[`Stylesheet] href="/static/mystyle.css" />
    <link
      rel=[`Stylesheet]
      href="https://cdn.jsdelivr.net/npm/katex@0.15.2/dist/katex.min.css"
    />
    <script
      defer="defer"
      src="https://cdn.jsdelivr.net/npm/katex@0.15.2/dist/katex.min.js"
    />
    <script
      defer="defer"
      src="https://cdn.jsdelivr.net/npm/katex@0.15.2/dist/contrib/auto-render.min.js"
      onload="renderMathInElement(document.body);"
    />
  </head>;

let menu_nav = se => {
  let f = p => <li> <a href={p.endpoint}> {Html.txt(p.name)} </a> </li>;
  let page_links = List.map(f, Memory.get_page_list());
  let connect_li =
    <li style="float:right">
      {if (!se.connected) {
         <a class_="connect" href="/login"> "Se connecter" </a>;
       } else {
         <a class_="disconnect" href="/logout"> "Se déconnecter" </a>;
       }}
    </li>;
  <nav> <ul> ...{page_links @ [connect_li]} </ul> </nav>;
};

/* ******************************************************************** */
/*                        Messages                                      */
/* ******************************************************************** */

let messages_div = se => {
  let f = x => <li> {Html.txt(x)} </li>;
  <div class_="orange-msg fullwidth">
    "Messages"
    <ul> ...{List.map(f, se.messages)} </ul>
  </div>;
};

/* ******************************************************************** */
/*                        Actions Menu                                  */
/* ******************************************************************** */

let document_action =
  <div> <a href="/documents"> {Html.txt("Liste des documents")} </a> </div>;

let edit_action = se =>
  <div>
    <a href={"/edit_markdown/" ++ se.active_page.id}> "Éditer la page" </a>
  </div>;

/* ******************************************************************** */
/*                        Markdown Page                                 */
/* ******************************************************************** */

let input_markdown_form = se =>
  <form action={"/upload_markdown/" ++ se.active_page.id} method=`Post>
    <input type_=`Hidden name="dream.csrf" value={se.csrf} />
    <textarea name="text"> {Html.txt(se.active_page.markdown)} </textarea>
    <button type_=`Submit> "Mettre à jour" </button>
  </form>;

let html_of_markdown = m =>
  m |> Omd.of_string |> Omd.to_html |> Html.Unsafe.data;

let markdown_page = se => {
  let body =
    <body>
      <header>
        <h1> "ENS Rennes - Promotion 2021 - Mathématiques" </h1>
      </header>
      {menu_nav(se)}
      <div>
        {if (se.connected) {
           <div class_="col-2"> {edit_action(se)} document_action </div>;
         } else {
           <div class_="col-2" />;
         }}
        <div class_="col-8">
          {html_of_markdown(se.active_page.markdown)}
        </div>
        <div class_="col-2" />
      </div>
    </body>;
  Html.html(html_head, body) |> html_to_string;
};

/* ******************************************************************** */
/*                        Login Page                                    */
/* ******************************************************************** */

let login_form = se =>
  <form action="/login" method=`Post>
    <input type_=`Hidden name="dream.csrf" value={se.csrf} />
    <h1> "Connexion" </h1>
    <div>
      <label for_="username"> "Nom d'utilisateur : " </label>
      <input type_=`Text name="username" />
    </div>
    <div>
      <label for_="password"> "Mot de passe : " </label>
      <input type_=`Password name="password" />
    </div>
    <button type_=`Submit> "Connexion" </button>
  </form>;

let login_page = se => {
  let body =
    <body>
      <header>
        <h1> "ENS Rennes - Promotion 2021 - Mathématiques" </h1>
      </header>
      <div>
        <div class_="col-2" />
        <div class_="col-8"> {login_form(se)} </div>
        <div class_="col-2" />
      </div>
    </body>;
  Html.html(html_head, body) |> html_to_string;
};

/* ******************************************************************** */
/*                        Documents Page                                */
/* ******************************************************************** */

let upload_documents_div = csrf_token =>
  <div class_="full-width">
    <form
      action="/upload_documents" method=`Post enctype="multipart/form-data">
      <input type_=`Hidden name="dream.csrf" value=csrf_token />
      <label> <input type_=`File name="file" /> </label>
      <button type_=`Submit> "Envoyer le document" </button>
    </form>
  </div>;

let document_list_div = _se => {
  let f = ((name, link)) => <li> <a href=link> {Html.txt(name)} </a> </li>;
  <div class_="full-width">
    <ul> ...{List.map(f, s.document_list)} </ul>
  </div>;
};

let documents_page = se => {
  let body =
    <body>
      <header>
        <h1> "ENS Rennes - Promotion 2021 - Mathématiques" </h1>
      </header>
      {menu_nav(se)}
      <div>
        <div class_="col-2" />
        <div class_="col-8">
          <h1> "Liste des documents" </h1>
          {document_list_div(se)}
          <h1> "Ajouter un document" </h1>
          {upload_documents_div(se.csrf)}
        </div>
        <div class_="col-2" />
      </div>
    </body>;
  Html.html(html_head, body) |> html_to_string;
};

/* ******************************************************************** */
/*                        Edit markdown page                            */
/* ******************************************************************** */

let edit_page = se => {
  let body =
    <body>
      <header>
        <h1> "ENS Rennes - Promotion 2021 - Mathématiques" </h1>
      </header>
      {menu_nav(se)}
      <div>
        <div class_="col-2" />
        <div class_="col-8"> {input_markdown_form(se)} </div>
        <div class_="col-2" />
      </div>
    </body>;
  Html.html(html_head, body) |> html_to_string;
};
