open BasicTypes

let read_whole_file filename =
  let ch = open_in filename in
  let s = really_input_string ch (in_channel_length ch) in
  close_in ch;
  s

(* The in memory state of the server is stored here *)
let page_list = [ "index"; "cours"; "test" ]
let documents : (string * string) list option ref = ref None
let pages : string StringMap.t ref = ref StringMap.empty
let messages : string list StringMap.t ref = ref StringMap.empty
let token : token option ref = ref None

(* There is helper fuunctions to access the state *)
let get_messages id = match StringMap.find_opt id !messages with Some l -> l | None -> []
let add_message id m = messages := StringMap.add id (m :: get_messages id) !messages

let get_token () =
  let update_token () =
    let* tok = Crypto.get_token () in
    token := Some tok;
    Lwt.return tok.token
  in
  match !token with
  | None -> update_token ()
  | Some tok -> if Unix.time () < tok.expiration then Lwt.return tok.token else update_token ()
