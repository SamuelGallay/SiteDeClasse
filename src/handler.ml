let ( let* ) = Lwt.bind
let main r = Rendering.index (Dream.csrf_token r)

let documents _r =
  let* l = Storage.get_objects () in
  Rendering.documents l

type code = [ `Not_Pushed | `Success | `Failure ]

let form r =
  let* res = Dream.multipart r in
  match res with
  | `Ok [ ("file", files) ] ->
      let f (name, content) =
        match name with
        | Some n ->
            let* res = Storage.push_file n content in
            Lwt.return (n, String.length content, (res :> code))
        | None -> Lwt.return ("This file don't have a name", String.length content, `Not_Pushed)
      in
      let* files = files |> List.map f |> Lwt.all in
      Rendering.files files
  | _ -> Dream.empty `Bad_Request
