open BasicTypes

(* The in memory state of the server is stored here *)
let server =
  {
    token = None;
    page_list = [ "index"; "cours"; "test" ];
    document_list = [];
    sessions = StringMap.empty;
  }

let empty_session () = { messages = []; active_page = "index" }

let get_session r =
  let id = Dream.session_id r in
  match StringMap.find_opt id server.sessions with
  | Some session -> session
  | None ->
      let new_session = empty_session () in
      server.sessions <- StringMap.add id new_session server.sessions;
      new_session

let get_token () =
  let update_token () =
    let* tok = Crypto.get_token () in
    server.token <- Some tok;
    Lwt.return tok.token
  in
  match server.token with
  | None -> update_token ()
  | Some tok -> if Unix.time () < tok.expiration then Lwt.return tok.token else update_token ()
