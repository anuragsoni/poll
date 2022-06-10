module Event = Event
module Backend = Backend
module Timeout = Timeout
module Poll_intf = Poll_intf
include Poll_intf.S

(** [create'] accepts a user-supplied polling implementation and uses it to create a new
    poller instance. *)
val create' : ?num_events:int -> (module Poll_intf.S) -> t

(** [backend] returns the io event notification backend (ex: kqueue, epoll, etc) used by
    the poller instance. *)
val backend : t -> Backend.t
