let check_readiness poll timeout =
  match Poll.wait poll timeout with
  | `Timeout -> print_endline "Timeout"
  | `Ok -> print_endline "Event available"
;;

let pair () =
  let a, b = Unix.socketpair Unix.PF_UNIX Unix.SOCK_STREAM 0 in
  Unix.set_nonblock a;
  Unix.set_nonblock b;
  a, b
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
