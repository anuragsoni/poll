[%%if ocaml_version < (4, 14, 0)]

(* emulate socketpair on windows so we can work with nonblocking file_descrs for tests.
   This can be removed once OCaml 4.14 is released as it will provide an implementation of
   socketpair on windows. Ref:
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

[%%else]

let pair_win32 () =
  let a, b = Unix.socketpair Unix.PF_UNIX Unix.SOCK_STREAM 0 in
  Unix.set_nonblock a;
  Unix.set_nonblock b;
  a, b
;;

[%%endif]

let check_readiness poll timeout =
  match Poll.wait poll timeout with
  | `Timeout -> print_endline "Timeout"
  | `Ok -> print_endline "Event available"
;;

let pair () =
  if Sys.os_type = "Win32"
  then pair_win32 ()
  else (
    let a, b = Unix.socketpair Unix.PF_UNIX Unix.SOCK_STREAM 0 in
    Unix.set_nonblock a;
    Unix.set_nonblock b;
    a, b)
;;

let%expect_test "Can poll for events" =
  let timeout = Poll.Timeout.after 1_000_000L in
  let r, w = pair () in
  let poll = Poll.create () in
  Poll.set poll r Poll.Event.read;
  (* No pending events should result in a timeout *)
  check_readiness poll timeout;
  [%expect {| Timeout |}];
  assert (Unix.write_substring w "Hello World" 0 11 = 11);
  (* The socket has data to read now, so an event should surface *)
  check_readiness poll timeout;
  [%expect {| Event available |}];
  let buf = Bytes.create 6 in
  Poll.iter_ready poll ~f:(fun fd event ->
      assert (fd = r);
      assert event.Poll.Event.readable;
      assert (not event.writable);
      assert (Unix.read r buf 0 6 = 6));
  Poll.clear poll;
  (* Poll events are oneshot. Querying the poller again will result in a timeout even
     though there is new data to read *)
  check_readiness poll timeout;
  [%expect {| Timeout |}];
  Poll.set poll r Poll.Event.read;
  check_readiness poll timeout;
  [%expect {| Event available |}];
  Poll.iter_ready poll ~f:(fun fd event ->
      assert (fd = r);
      assert event.Poll.Event.readable;
      assert (not event.writable);
      assert (Unix.read r buf 0 6 = 5));
  Poll.clear poll;
  (* With the entire payload consumed, poller will return a timeout again. *)
  check_readiness poll timeout;
  [%expect {| Timeout |}]
;;
