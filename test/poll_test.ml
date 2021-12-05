let check_readiness poll timeout =
  match Poll.wait poll timeout with
  | `Timeout -> print_endline "Timeout"
  | `Ok -> print_endline "Event available"
;;

(* emulate socketpair on windows so we can work with nonblocking file_descrs for tests.
   This can be removed once OCaml 4.14 is released as it will provide an implementation of
   socketpair on windows.

   Ref:
   https://github.com/ocaml/ocaml/blob/337079942982cad005f5ba37854bddd696d8595b/Changes#L130-L132 *)
let pair_win32 () =
  let a = Unix.socket Unix.PF_INET Unix.SOCK_STREAM 0 in
  let b = Unix.socket Unix.PF_INET Unix.SOCK_STREAM 0 in
  Unix.bind a (Unix.ADDR_INET (Unix.inet_addr_loopback, 0));
  let addr = Unix.getsockname a in
  Unix.listen a 1;
  Unix.set_nonblock b;
  (try Unix.connect b addr with
  | Unix.Unix_error (EWOULDBLOCK, _, _) -> ());
  match Unix.select [ a ] [] [] 1. with
  | [ a' ], [], [] ->
    if a <> a' then failwith "Could not connect client socket";
    let c, _ = Unix.accept a in
    Unix.set_nonblock c;
    Unix.close a;
    b, c
  | [], [], [] ->
    Unix.close a;
    Unix.close b;
    failwith "Could not connect client socket"
  | _ -> assert false
;;

let pair () =
  if Sys.os_type = "Win32"
  then pair_win32 ()
  else (
    let a, b = Unix.pipe () in
    Unix.set_nonblock a;
    Unix.set_nonblock b;
    a, b)
;;

let%expect_test "test poll" =
  let r, w = pair () in
  let poll = Poll.create () in
  Poll.set poll r Poll.Event.read;
  check_readiness poll (Poll.Timeout.after 1_000_000L);
  [%expect {| Timeout |}];
  ignore (Unix.write_substring w "Hello" 0 5);
  check_readiness poll (Poll.Timeout.after 1_000_000L);
  [%expect {| Event available |}]
;;
