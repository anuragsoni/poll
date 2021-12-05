[%%import "config.h"]
[%%if defined POLL_CONF_WIN32]

let available = true

module Ffi = struct
  external epoll_create1 : unit -> Unix.file_descr = "poll_stub_wepoll_create1"
  external epoll_in : unit -> int = "poll_stub_epollin"
  external epoll_rdhup : unit -> int = "poll_stub_epollrdhup"
  external epoll_hup : unit -> int = "poll_stub_epollhup"
  external epoll_err : unit -> int = "poll_stub_epollerr"
  external epoll_pri : unit -> int = "poll_stub_epollpri"
  external epoll_out : unit -> int = "poll_stub_epollout"
  external epoll_event_sizeof : unit -> int = "poll_stub_epoll_event_sizeout"

  external epoll_ctl_add
    :  Unix.file_descr
    -> Unix.file_descr
    -> int
    -> unit
    = "poll_stub_epoll_ctl_add"

  external epoll_ctl_mod
    :  Unix.file_descr
    -> Unix.file_descr
    -> int
    -> unit
    = "poll_stub_epoll_ctl_mod"

  external epoll_ctl_del
    :  Unix.file_descr
    -> Unix.file_descr
    -> unit
    = "poll_stub_epoll_ctl_del"

  external epoll_wait
    :  Unix.file_descr
    -> Bigstring.t
    -> int
    -> int
    = "poll_stub_epoll_wait"

  external epoll_iter_ready
    :  Bigstring.t
    -> int
    -> (Unix.file_descr -> int -> unit)
    -> unit
    = "poll_stub_epoll_iter_ready"

  let epoll_event_sizeof = epoll_event_sizeof ()
  let epoll_in = epoll_in ()
  let epoll_rdhup = epoll_rdhup ()
  let epoll_hup = epoll_hup ()
  let epoll_err = epoll_err ()
  let epoll_pri = epoll_pri ()
  let epoll_out = epoll_out ()
  let flag_read = epoll_in lor epoll_rdhup lor epoll_hup lor epoll_err lor epoll_pri
  let flag_write = epoll_out lor epoll_hup lor epoll_err
end

type t =
  { epoll_fd : Unix.file_descr
  ; mutable ready_events : int
  ; events : Bigstring.t
  ; mutable closed : bool
  ; flags : (Unix.file_descr, int) Hashtbl.t
  }

let ensure_open t = if t.closed then failwith "Attempting to use a closed epoll fd"
let backend = Backend.Wepoll

let create () =
  { epoll_fd = Ffi.epoll_create1 ()
  ; ready_events = 0
  ; events = Bigstring.create (256 * Ffi.epoll_event_sizeof)
  ; closed = false
  ; flags = Hashtbl.create 65536
  }
;;

let clear t =
  ensure_open t;
  t.ready_events <- 0
;;

let close t =
  if not t.closed
  then (
    t.closed <- true;
    Unix.close t.epoll_fd)
;;

let set t fd event =
  ensure_open t;
  let current_flags = Hashtbl.find_opt t.flags fd in
  let new_flags =
    match event.Event.readable, event.Event.writable with
    | false, false -> None
    | true, false -> Some Ffi.flag_read
    | false, true -> Some Ffi.flag_write
    | true, true -> Some Ffi.(flag_read lor flag_write)
  in
  match current_flags, new_flags with
  | None, None -> ()
  | None, Some f ->
    Ffi.epoll_ctl_add t.epoll_fd fd f;
    Hashtbl.replace t.flags fd f
  | Some _, None ->
    Ffi.epoll_ctl_del t.epoll_fd fd;
    Hashtbl.remove t.flags fd
  | Some a, Some b ->
    if a <> b
    then (
      Ffi.epoll_ctl_mod t.epoll_fd fd b;
      Hashtbl.replace t.flags fd b)
;;

let wait t timeout =
  let timeout =
    match timeout with
    | Timeout.Immediate -> 0
    | Never -> -1
    | After x -> Int64.to_int (Int64.div x 1_000_000L)
  in
  ensure_open t;
  t.ready_events <- 0;
  t.ready_events <- Ffi.epoll_wait t.epoll_fd t.events timeout;
  if t.ready_events = 0 then `Timeout else `Ok
;;

let iter_callback f fd flags =
  let readable = flags land Ffi.flag_read <> 0 in
  let writable = flags land Ffi.flag_write <> 0 in
  f fd { Event.readable; writable }
;;

let iter_ready t ~f =
  ensure_open t;
  let callback = iter_callback f in
  Ffi.epoll_iter_ready t.events t.ready_events callback
;;

[%%else]

include Empty_poll

let available = false

[%%endif]
