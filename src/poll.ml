module Event = Event
module Backend = Backend
module Timeout = Timeout
module Poll_intf = Poll_intf

let backends =
  [ (module Kqueue_poll : Poll_intf.S), Kqueue.available
  ; (module Epoll_poll : Poll_intf.S), Epoll_poll.available
  ; (module Empty_poll : Poll_intf.S), true
  ]
;;

module Poll = struct
  module type S = sig
    include Poll_intf.S

    val poll : t
  end

  type t = (module S)
end

type t = Poll.t

let create' ?num_events backend =
  let module P = struct
    include (val backend : Poll_intf.S)

    let poll = create ?num_events ()
  end
  in
  (module P : Poll.S)
;;

let create ?num_events () =
  let backend =
    let rec aux = function
      | [] -> failwith "No poll backend found"
      | (poll, available) :: xs ->
        let module P = (val poll : Poll_intf.S) in
        if available then poll else aux xs
    in
    aux backends
  in
  create' ?num_events backend
;;

let backend t =
  let module P = (val t : Poll.S) in
  P.backend
;;

let set t fd event =
  let module P = (val t : Poll.S) in
  P.set P.poll fd event
;;

let wait t timeout =
  let module P = (val t : Poll.S) in
  P.wait P.poll timeout
;;

let iter_ready t ~f =
  let module P = (val t : Poll.S) in
  P.iter_ready P.poll ~f
;;

let clear t =
  let module P = (val t : Poll.S) in
  P.clear P.poll
;;

let close t =
  let module P = (val t : Poll.S) in
  P.close P.poll
;;
