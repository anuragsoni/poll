type t = (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t

let create size = Bigarray.(Array1.create char c_layout size)

external swap32 : int32 -> int32 = "%bswap_int32"
external swap64 : int64 -> int64 = "%bswap_int64"
external swap16 : int -> int = "%bswap16"
external unsafe_get_int32 : t -> int -> int32 = "%caml_bigstring_get32u"
external unsafe_set_int32 : t -> int -> int32 -> unit = "%caml_bigstring_set32u"
external unsafe_get_int16 : t -> int -> int = "%caml_bigstring_get16u"
external unsafe_set_int16 : t -> int -> int -> unit = "%caml_bigstring_set16u"
external unsafe_get_int64 : t -> int -> int64 = "%caml_bigstring_get64u"
external unsafe_set_int64 : t -> int -> int64 -> unit = "%caml_bigstring_set64u"

let unsafe_get_int64_le_trunc_swap t ~pos = Int64.to_int (swap64 (unsafe_get_int64 t pos))
let unsafe_get_int64_le_trunc t ~pos = Int64.to_int (unsafe_get_int64 t pos)

let unsafe_get_int64_le_trunc =
  if Sys.big_endian then unsafe_get_int64_le_trunc_swap else unsafe_get_int64_le_trunc
;;

let unsafe_set_int64_swap t ~pos v = unsafe_set_int64 t pos (swap64 (Int64.of_int v))
let unsafe_set_int64 t ~pos v = unsafe_set_int64 t pos (Int64.of_int v)

let unsafe_set_int64_le =
  if Sys.big_endian then unsafe_set_int64_swap else unsafe_set_int64
;;

let unsafe_get_int32_le_swap t ~pos = Int32.to_int (swap32 (unsafe_get_int32 t pos))
let unsafe_get_int32_le t ~pos = Int32.to_int (unsafe_get_int32 t pos)

let unsafe_get_int32_le =
  if Sys.big_endian then unsafe_get_int32_le_swap else unsafe_get_int32_le
;;

let unsafe_set_int32_le_swap t ~pos v = unsafe_set_int32 t pos (swap32 (Int32.of_int v))
let unsafe_set_int32_le t ~pos v = unsafe_set_int32 t pos (Int32.of_int v)

let unsafe_set_int32_le =
  if Sys.big_endian then unsafe_set_int32_le_swap else unsafe_set_int32_le
;;

let sign_extend_16 u = (u lsl (Sys.int_size - 16)) asr (Sys.int_size - 16)
let unsafe_get_int16_le_swap t ~pos = sign_extend_16 (swap16 (unsafe_get_int16 t pos))
let unsafe_get_int16_le t ~pos = sign_extend_16 (unsafe_get_int16 t pos)

let unsafe_get_int16_le =
  if Sys.big_endian then unsafe_get_int16_le_swap else unsafe_get_int16_le
;;

let unsafe_set_int16_le_swap t ~pos v = unsafe_set_int16 t pos (swap16 v)
let unsafe_set_int16_le t ~pos v = unsafe_set_int16 t pos v

let unsafe_set_int16_le =
  if Sys.big_endian then unsafe_set_int16_le_swap else unsafe_set_int16_le
;;
