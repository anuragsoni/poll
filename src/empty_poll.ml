type t = [ `Empty ]
type Backend.t += Empty

let backend = Empty
let create () = failwith "No polling backend available"
let set _ _ _ = failwith "No polling backend available"
let wait _ _ = failwith "No polling backend available"
let clear _ = failwith "No polling backend available"
let iter_ready _ ~f:_ = failwith "No polling backend available"
let close _ = ()
