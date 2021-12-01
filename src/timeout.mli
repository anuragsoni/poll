(** [Timeout.t] represents the maximum interval a poller will wait for a new event. *)
type t =
  | Immediate
  | Never
  | After of int64

val immediate : t
val never : t

(** Timespan in nanoseconds. *)
val after : int64 -> t
