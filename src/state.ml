let (documents : (string * string) list option ref) = ref None

let content =
  let open Tyxml.Html in
  div ~a:[] [ h1 [ txt "This is cool" ]; txt "Lorem ipsum dolor sit amet, consectetur..." ]

let read_whole_file filename =
  let ch = open_in filename in
  let s = really_input_string ch (in_channel_length ch) in
  close_in ch;
  s

let test = ref (read_whole_file "pages/main.md")