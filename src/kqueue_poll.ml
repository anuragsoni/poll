open! Import

type t =
  { kqueue : Kqueue.t
  ; eventlist : Kqueue.Event_list.t
  ; mutable ready_events : int
  }

let backend = Backend.Kqueue

let create () =
  let eventlist = Kqueue.Event_list.create 256 in
  { kqueue = Kqueue.create (); eventlist; ready_events = 0 }
;;

let fill_event ident event flags filter =
  Kqueue.Event_list.Event.set_ident event ident;
  Kqueue.Event_list.Event.set_filter event filter;
  Kqueue.Event_list.Event.set_flags event flags;
  Kqueue.Event_list.Event.set_fflags event Kqueue.Note.empty;
  Kqueue.Event_list.Event.set_data event 0;
  Kqueue.Event_list.Event.set_udata event 0
;;

let register_events t changelist timeout =
  let len = Kqueue.kevent t.kqueue ~changelist ~eventlist:changelist timeout in
  for idx = 0 to len - 1 do
    let event = Kqueue.Event_list.get changelist idx in
    let flags = Kqueue.Event_list.Event.get_flags event in
    let data = Kqueue.Event_list.Event.get_data event in
    if Kqueue.Flag.(intersect flags error)
       && data <> 0
       && data <> Import.unix_error_to_int Unix.ENOENT
       && data <> Import.unix_error_to_int Unix.EPIPE
    then raise (Unix.Unix_error (Import.unix_error_of_int data, "kevent", ""))
  done
;;

let set t fd event =
  let changelist = Kqueue.Event_list.create 2 in
  let ident = Kqueue.Util.file_descr_to_int fd in
  let read_flags =
    if event.Event.readable
    then Kqueue.Flag.(add + receipt)
    else Kqueue.Flag.delete
  in
  let write_flags =
    if event.writable then Kqueue.Flag.(add + receipt) else Kqueue.Flag.delete
  in
  let idx = ref 0 in
  fill_event ident (Kqueue.Event_list.get changelist !idx) read_flags Kqueue.Filter.read;
  incr idx;
  fill_event ident (Kqueue.Event_list.get changelist !idx) write_flags Kqueue.Filter.write;
  register_events t changelist Kqueue.Timeout.never
;;

let wait t timeout =
  t.ready_events <- 0;
  t.ready_events
    <- Kqueue.kevent
         t.kqueue
         ~changelist:Kqueue.Event_list.null
         ~eventlist:t.eventlist
         (Kqueue.Timeout.of_ns timeout);
  if t.ready_events = 0 then `Timeout else `Ok
;;

let clear t = t.ready_events <- 0

let iter_ready t ~f =
  for i = 0 to t.ready_events - 1 do
    let event = Kqueue.Event_list.get t.eventlist i in
    let ident = Kqueue.Event_list.Event.get_ident event in
    let flags = Kqueue.Event_list.Event.get_flags event in
    let filter = Kqueue.Event_list.Event.get_filter event in
    let readable = Kqueue.Filter.(filter = read) in
    let writable =
      Kqueue.Filter.(filter = write) || (readable && Kqueue.Flag.(intersect flags eof))
    in
    f (Kqueue.Util.file_descr_of_int ident) { Event.readable; writable }
  done
;;

let close t = Kqueue.close t.kqueue
