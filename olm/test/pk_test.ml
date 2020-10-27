open! Core
open! Olm
open! Helpers.ResultInfix
open! Obenkyo

let main () =
  print_endline "Running Pk tests...";

  let () =
    test "invalid encryption" begin
      Pk.Encryption.create ""
      |> Result.is_error
    end
  in

  let () =
    test "encryption" begin
      let plaintext = "I've got a secret." in
      begin
        Pk.Decryption.create ()             >>= fun dec ->
        Pk.Encryption.create dec.pubkey     >>= fun enc ->
        Pk.Encryption.encrypt enc plaintext >>=
        Pk.Decryption.decrypt dec
      end |> function
      | Ok s when String.equal s plaintext -> true
      | _                                  -> false
    end
  in

  let () =
    test "invalid decrpytion" begin
      let plaintext = "I've got a secret." in
      begin
        Pk.Decryption.create ()             >>= fun dec ->
        Pk.Encryption.create dec.pubkey     >>= fun enc ->
        Pk.Encryption.encrypt enc plaintext >>= fun msg ->
        { msg with ephemeral_key ="?" }
        |> Pk.Decryption.decrypt dec
      end |> function
      | Error "BAD_MESSAGE_MAC" -> true
      | _                       -> false
    end
  in

  let () =
    test "pickle" begin
      let plaintext = "I've got a secret." in
      begin
        Pk.Decryption.create ()             >>= fun dec ->
        Pk.Encryption.create dec.pubkey     >>= fun enc ->
        Pk.Encryption.encrypt enc plaintext >>= fun msg ->
        Pk.Decryption.pickle dec            >>=
        Pk.Decryption.from_pickle           >>= fun unpickled ->
        Pk.Decryption.decrypt unpickled msg
      end |> function
      | Ok s when String.equal s plaintext -> true
      | _                                  -> false
    end
  in

  let () =
    test "invalid unpickle" begin
      Pk.Decryption.from_pickle "" |> Result.is_error
    end
  in

  let () =
    test "invalid pass pickling" begin
      begin
        Pk.Decryption.create () >>=
        Pk.Decryption.pickle ~pass:"foo" >>=
        Pk.Decryption.from_pickle ~pass:"bar"
      end |> function
      | Error "BAD_ACCOUNT_KEY" -> true
      | _                       -> false
    end
  in

  let () =
    test "signature verification" begin
      let seed      = Pk.Signing.generate_seed () in
      let plaintext = "Hello there!" in
      let util      = Utility.create () in
      begin
        Pk.Signing.create seed >>= fun signing ->
        Pk.Signing.sign signing plaintext >>=
        Utility.ed25519_verify util signing.pubkey plaintext
      end |> Result.is_ok
    end
  in

  (* TODO: Not sure what I need to do to test invalid unicode decrypt as they
   * do in the python bindings. I also have not determined what my equivalent
   * course is when unicode handling is done in the API. *)
  let () =
    test "unicode decrypt" begin
      let unicode = "😀" in
      begin
        Pk.Decryption.create ()           >>= fun dec ->
        Pk.Encryption.create dec.pubkey   >>= fun enc ->
        Pk.Encryption.encrypt enc unicode >>=
        Pk.Decryption.decrypt dec
      end |> function
      | Ok "😀" -> true
      | _     -> false
    end
  in

  print_endline "Done!"