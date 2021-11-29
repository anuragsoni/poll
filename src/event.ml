type t =
  { readable : bool
  ; writable : bool
  }

let read = { readable = true; writable = false }
let none = { readable = false; writable = false }
let write = { readable = false; writable = false }
let read_write = { readable = true; writable = true }
