let create_sock port =
  let socket = Unix.socket ~cloexec:true Unix.PF_INET Unix.SOCK_STREAM 0 in
  Unix.set_nonblock socket;
  let addr = Unix.inet_addr_of_string "127.0.0.1" in
  Unix.bind socket (Unix.ADDR_INET (addr, port));
  Unix.listen socket 128;
  socket
;;

let rec accept poll sock =
  try
    let client_fd, _ = Unix.accept sock in
    Unix.set_nonblock client_fd;
    Poll.set poll client_fd Poll.Event.read;
    accept poll sock
  with
  | Unix.Unix_error (Unix.(EWOULDBLOCK | EAGAIN), _, _) -> ()
;;

let rec read fd buf ~pos ~len =
  try
    let c = Unix.read fd buf pos len in
    if c = 0
    then `Eof
    else (
      ignore (Unix.write fd buf 0 c);
      read fd buf ~pos ~len)
  with
  | Unix.Unix_error (Unix.(EWOULDBLOCK | EAGAIN), _, _) -> `Poll_again
;;

let () =
  Printexc.record_backtrace true;
  let sock = create_sock 12345 in
  let poll = Poll.create () in
  let buf = Bytes.create 1024 in
  Poll.set poll sock Poll.Event.read;
  let rec loop () =
    Poll.clear poll;
    match Poll.wait poll (Duration.of_ms 10) with
    | `Timeout -> loop ()
    | `Ok ->
      Poll.iter_ready poll ~f:(fun fd _event ->
          if fd = sock
          then accept poll sock
          else (
            match read fd buf ~pos:0 ~len:1024 with
            | `Poll_again -> ()
            | `Eof ->
              Poll.set poll fd Poll.Event.none;
              Unix.close fd
            | `Ok c -> ignore (Unix.write fd buf 0 c)));
      loop ()
  in
  loop ()
;;
