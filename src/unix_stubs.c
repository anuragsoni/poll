#include <caml/mlvalues.h>
#include <caml/unixsupport.h>

CAMLprim value poll_unix_error_of_int(value err) {
  return unix_error_of_code(Int_val(err));
}

CAMLprim value poll_int_of_unix_error(value err) {
  return Val_int(code_of_unix_error(err));
}
