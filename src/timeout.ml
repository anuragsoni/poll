type t =
  | Immediate
  | Never
  | After of int64

let immediate = Immediate
let never = Never
let after x = After x
