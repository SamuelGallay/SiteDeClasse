let (documents : (string * string) list option ref) = ref None

let content =
  let open Tyxml.Html in
  div ~a:[] [ h1 [ txt "This is cool" ]; txt "Lorem ipsum dolor sit amet, consectetur..." ]
