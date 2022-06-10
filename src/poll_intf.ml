module type S = sig
  type t

  val backend : Backend.t

  (** [create ?num_events ()] creates a new instance of a poller. num_events is an
      optional input that can be used to specify how many events to look for when a poller
      waits for new events. *)
  val create : ?num_events:int -> unit -> t

  (** [set t fd event] updates the state of the set of file descriptors monitored by the
      poller. [Event.none] can be used to delete a fd from the set of descriptors that are
      monitored. *)
  val set : t -> Unix.file_descr -> Event.t -> unit

  (** [wait t timeout] waits for at least one event to be ready, unless the user provides
      timeout is reached. *)
  val wait : t -> Timeout.t -> [ `Ok | `Timeout ]

  (** [clear] clears the number of i/o events that are ready to be consumed. This should
      be called after the user consumes all events that are available after [wait]. *)
  val clear : t -> unit

  (** [iter_ready] iterates over the events that are ready after a call to [wait]. *)
  val iter_ready : t -> f:(Unix.file_descr -> Event.t -> unit) -> unit

  (** [close] closes the poller instance. *)
  val close : t -> unit
end
