open Monocypher
open Bip32_ed25519

module Crypto = struct
  let sha256 = Hacl.Hash.SHA256.digest
  let hmac_sha512 ~key msg = Hacl.Hash.SHA512.HMAC.digest ~key ~msg
end

let c = (module Crypto : CRYPTO)

let basic_one i =
  let _seed, ek = random c in
  let pk = neuterize ek in
  let ek' = derive_exn c ek 0l in
  let pk' = derive_exn c pk 0l in
  let pk'' = neuterize ek' in
  Alcotest.(check bool (Printf.sprintf "basic %d" i) true (Bip32_ed25519.equal pk' pk''))

let basic () =
  for i = 0 to 10 do
    basic_one i
  done

let serialization () =
  let _seed, ek = random c in
  let pk = neuterize ek in
  let ek1 = derive_exn c ek 32l in
  let buf = to_bytes ek in
  let ek' = unsafe_ek_of_bytes buf in
  assert (equal ek ek') ;
  let buf = to_bytes ek1 in
  let ek1' = unsafe_ek_of_bytes buf in
  assert (equal ek1 ek1') ;
  let buf = to_bytes pk in
  let pk' = unsafe_pk_of_bytes buf in
  assert (equal pk pk')

module HR = struct
  open Human_readable
  let of_string () =
    match path_of_string "44'/1'/0'/0/0" with
    | None -> assert false
    | Some [a; b; c; 0l; 0l] when
        a = to_hardened 44l &&
        b = to_hardened 1l &&
        c = to_hardened 0l -> ()
    | _ -> assert false

  let to_string () =
    let res =
      string_of_path [to_hardened 44l; to_hardened 1l; to_hardened 0l; 0l; 0l] in
    Printf.printf "%s\n%!" res ;
    assert (res = "44'/1'/0'/0/0") ;
    let res = string_of_path [] in
    assert (res = "") ;
    let res = string_of_path [to_hardened 2l; 123l] in
    assert (res = "2'/123")

  let of_string_exn_fail () =
    match path_of_string_exn "//" with
    | exception _ -> ()
    | _ -> assert false

  let of_string_exn_success () =
    ignore (path_of_string_exn "") ;
    ignore (path_of_string_exn "1/2") ;
    ignore (path_of_string_exn "1/2'/3'/0") ;
    ()
end

let basic = [
  "basic", `Quick, basic ;
  "serialization", `Quick, serialization ;
]

let human_readable = HR.[
    "of_string", `Quick, of_string ;
    "of_string_exn_fail", `Quick, of_string_exn_fail ;
    "of_string_exn_success", `Quick, of_string_exn_success ;
    "to_string", `Quick, to_string ;
  ]

let () =
  Alcotest.run "Bip32_ed25519" [
    "basic", basic ;
    "human_readable", human_readable ;
  ]
