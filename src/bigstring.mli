type t = (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t

val create : int -> t
val unsafe_get_int64_le_trunc : t -> pos:int -> int
val unsafe_set_int64_le : t -> pos:int -> int -> unit
val unsafe_get_int32_le : t -> pos:int -> int
val unsafe_set_int32_le : t -> pos:int -> int -> unit
val unsafe_get_int16_le : t -> pos:int -> int
val unsafe_set_int16_le : t -> pos:int -> int -> unit
