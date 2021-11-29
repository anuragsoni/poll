let check_readiness poll timeout =
  match Poll.wait poll timeout with
  | `Timeout -> print_endline "Timeout"
  | `Ok -> print_endline "Event available"
;;

let%expect_test "test poll" =
  let r, w = Unix.pipe () in
  let poll = Poll.create () in
  Poll.set poll r Poll.Event.read;
  check_readiness poll (Duration.of_ms 10);
  [%expect {| Timeout |}];
  ignore (Unix.write_substring w "Hello" 0 5);
  check_readiness poll (Duration.of_ms 10);
  [%expect {| Event available |}]
;;
