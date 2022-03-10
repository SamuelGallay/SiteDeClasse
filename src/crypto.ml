(* ******************************************************************** *)
(*                      Utilitary and Base64url                         *)
(* ******************************************************************** *)
open Json
open BasicTypes

let sprintf = Format.sprintf
let ( let* ) = Lwt.bind
let remove_trailing_dots = Str.global_replace (Str.regexp {|\.*$|}) ""

let base64url s =
  match Base64.encode ~pad:false ~alphabet:Base64.uri_safe_alphabet s with
  | Ok s -> s
  | Error (`Msg s) -> failwith s

(* ******************************************************************** *)
(*                          Import Key                                  *)
(* ******************************************************************** *)

let string_private_key_of_json s =
  let j = Json.private_key_of_yojson (Yojson.Safe.from_string s) in
  j.private_key

let string_private_key = Sys.getenv "WEBSITE_PRIVATE_KEY"

let mirage_private_key =
  match X509.Private_key.decode_pem (Cstruct.of_string string_private_key) with
  | Ok (`RSA k) -> k
  | Ok _ -> failwith "Wrong key format"
  | Error (`Msg s) -> failwith ("Error in m : " ^ s)

(* ******************************************************************** *)
(*                          Signature                                   *)
(* ******************************************************************** *)

let base64url_signature_RSA_SHA256 s =
  Mirage_crypto_pk.Rsa.PKCS1.sign ~hash:`SHA256 ~key:mirage_private_key
    (`Message (Cstruct.of_string s))
  |> Cstruct.to_string |> base64url

(* ******************************************************************** *)
(*                       Creating Request                               *)
(* ******************************************************************** *)

let create_jwt () =
  let header =
    { alg = "RS256"; typ = "JWT" } |> Json.yojson_of_header |> Yojson.Safe.to_string |> base64url
  in
  let time = int_of_float (Unix.time ()) in
  let claim_set =
    {
      iss = "webserver@erudite-descent-342509.iam.gserviceaccount.com";
      scope = "https://www.googleapis.com/auth/devstorage.read_write";
      aud = "https://oauth2.googleapis.com/token";
      exp = time + 3000;
      iat = time;
    }
    |> yojson_of_claim_set |> Yojson.Safe.to_string |> base64url
  in
  let signature = base64url_signature_RSA_SHA256 (header ^ "." ^ claim_set) in
  sprintf "%s.%s.%s" header claim_set signature

let get_token () =
  let open Cohttp_lwt_unix in
  let jwt = create_jwt () in
  let url = "https://oauth2.googleapis.com/token" in
  let uri =
    Uri.with_query' (Uri.of_string url)
      [ ("grant_type", "urn:ietf:params:oauth:grant-type:jwt-bearer"); ("assertion", jwt) ]
  in
  let* _resp, body = Client.post uri in
  let* json_string = Cohttp_lwt.Body.to_string body in
  let access_token = access_token_of_yojson (Yojson.Safe.from_string json_string) in
  Lwt.return
    { token = remove_trailing_dots access_token.access_token; expiration = Unix.time () +. 2500. }
