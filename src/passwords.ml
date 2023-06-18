open BasicTypes

let sprintf = Format.sprintf
let printf = Format.printf

let push content =
  let* resp = Storage.push_file `Private "users.json" content in
  match resp with
  | Error _ -> Lwt_io.printf "Failed to push\n"
  | Ok _ -> Lwt_io.printf "Push succeeded\n"

let get () =
  let* resp = Storage.get_file `Private "users.json" in
  match resp with Error _ -> failwith "Get Failed" | Ok f -> Lwt.return f

type mode = NoMode | AddMode | ListMode | CheckMode

let mode = ref NoMode
let user = ref ""
let psswd = ref ""
let usage_message = "passwords add --user <user> --password <password>"

let set_mode s =
  match !mode with
  | AddMode | CheckMode | ListMode -> failwith "Can't use multiple modes"
  | NoMode -> (
      match s with
      | "add" -> mode := AddMode
      | "list" -> mode := ListMode
      | "check" -> mode := CheckMode
      | s -> failwith (sprintf "Unknown mode %s" s))

let speclist =
  [ ("--user", Arg.Set_string user, "Username"); ("--password", Arg.Set_string psswd, "Password") ]

let random n =
  let s = Mirage_crypto_rng.generate n |> Cstruct.to_string in
  if String.length s = n then s else failwith "Random Failure (It's life!)"

let argon2 pwd =
  let open Argon2 in
  let hash_len = 32 in
  let t_cost = 2 in
  let m_cost = 65536 in
  let parallelism = 1 in
  let salt = random 16 in
  let salt_len = String.length salt in
  let encoded_len = encoded_len ~t_cost ~m_cost ~parallelism ~salt_len ~hash_len ~kind:ID in
  match ID.hash_encoded ~t_cost ~m_cost ~parallelism ~pwd ~salt ~hash_len ~encoded_len with
  | Ok hash -> ID.encoded_to_string hash
  | Error _ -> failwith "Hash failed"

let users = ref StringMap.empty

let verify user_name pwd =
  let encoded = StringMap.find user_name !users in
  match Argon2.verify ~encoded ~pwd ~kind:Argon2.ID with
  | Ok b -> if b then Lwt_io.printf "Correct\n" else Lwt_io.printf "Wrong Password\n"
  | Error s -> Lwt_io.printf "Error : %s\n" (Argon2.ErrorCodes.message s)

let main () =
  Mirage_crypto_rng_lwt.initialize (module Mirage_crypto_rng.Fortuna);
  let () = Arg.parse speclist set_mode usage_message in
  match !mode with
  | NoMode -> failwith "No mode selected"
  | AddMode ->
      if !user = "" || !psswd = "" then failwith "Wrong Arguments";
      let* c = get () in
      let ul = c |> Yojson.Safe.from_string |> user_list_of_yojson in
      List.iter (fun u -> users := StringMap.add u.pseudo u.hashed_password !users) ul;
      let hashed_password = argon2 !psswd in
      users := StringMap.add !user hashed_password !users;
      let usrlist =
        !users |> StringMap.to_seq |> List.of_seq
        |> List.map (fun (u, p) -> { pseudo = u; hashed_password = p })
        |> yojson_of_user_list |> Yojson.Safe.to_string
      in
      push usrlist
  | ListMode ->
      let* c = get () in
      Lwt_io.printf "Content:\n%s\n" c
  | CheckMode ->
      if !user = "" || !psswd = "" then failwith "Wrong Arguments";
      let* c = get () in
      let ul = c |> Yojson.Safe.from_string |> user_list_of_yojson in
      List.iter (fun u -> users := StringMap.add u.pseudo u.hashed_password !users) ul;
      verify !user !psswd

let () = Lwt_main.run (main ())
