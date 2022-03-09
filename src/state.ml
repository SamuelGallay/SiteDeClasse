module StringMap = Map.Make (String)

let read_whole_file filename =
  let ch = open_in filename in
  let s = really_input_string ch (in_channel_length ch) in
  close_in ch;
  s

let (documents : (string * string) list option ref) = ref None
let test = ref (read_whole_file "pages/main.md")
let (messages : string list StringMap.t ref) = ref StringMap.empty
let get_messages id = match StringMap.find_opt id !messages with Some l -> l | None -> []
let add_message id m = messages := StringMap.add id (m :: get_messages id) !messages
