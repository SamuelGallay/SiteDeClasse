let ( let* ) = Lwt.bind

let documents _r =
  let* l = Storage.get_objects () in
  Rendering.documents l
