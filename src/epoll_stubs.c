#include "config.h"

#if defined(POLL_CONF_LINUX)
#include <caml/alloc.h>
#include <caml/bigarray.h>
#include <caml/callback.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>
#include <caml/signals.h>
#include <caml/threads.h>
#include <caml/unixsupport.h>
#include <errno.h>
#include <sys/epoll.h>

#define Epoll_constant(name, i)                                                \
    CAMLprim value name(value unit) { return Val_int(i); }

  Epoll_constant(poll_stub_epollin, EPOLLIN)
  Epoll_constant(poll_stub_epollet, EPOLLET)
  Epoll_constant(poll_stub_epollrdhup, EPOLLRDHUP)
  Epoll_constant(poll_stub_epollhup, EPOLLHUP)
  Epoll_constant(poll_stub_epollerr, EPOLLERR)
  Epoll_constant(poll_stub_epollpri, EPOLLPRI)
  Epoll_constant(poll_stub_epollout, EPOLLOUT)
  Epoll_constant(poll_stub_epolloneshot, EPOLLONESHOT)

  CAMLprim value poll_stub_epoll_create1(value unit) {
    CAMLparam1(unit);
    int fd;
    fd = epoll_create1(EPOLL_CLOEXEC);
    if (fd == -1)
      uerror("epoll_create1", Nothing);
    CAMLreturn(Val_long(fd));
  }

  CAMLprim value poll_stub_epoll_event_sizeout(value unit) {
    return Val_long(sizeof(struct epoll_event));
  }

  CAMLprim value poll_stub_epoll_fd_offset(value unit) {
    return Val_int(offsetof(struct epoll_event, data.fd));
  }

  CAMLprim value poll_stub_epoll_flag_offset(value unit) {
    return Val_int(offsetof(struct epoll_event, events));
  }

  static value poll_stub_epoll_ctl(value epoll_fd, value fd, value flags, int operation) {
    CAMLparam3(epoll_fd, fd, flags);
    struct epoll_event evt;
    evt.data.ptr = NULL;
    evt.events = Int_val(flags);
    evt.data.fd = Long_val(fd);
    if (epoll_ctl(Long_val(epoll_fd), operation, Long_val(fd), &evt) == -1)
      uerror("epoll_ctl", Nothing);
    CAMLreturn(Val_unit);
  }

  CAMLprim value poll_stub_epoll_ctl_add(value epoll_fd, value fd, value flags) {
    return poll_stub_epoll_ctl(epoll_fd, fd, flags, EPOLL_CTL_ADD);
  }

  CAMLprim value poll_stub_epoll_ctl_mod(value epoll_fd, value fd, value flags) {
    return poll_stub_epoll_ctl(epoll_fd, fd, flags, EPOLL_CTL_MOD);
  }

  CAMLprim value poll_stub_epoll_ctl_del(value epoll_fd, value fd) {
    if (epoll_ctl(Long_val(epoll_fd), EPOLL_CTL_DEL, Long_val(fd), NULL) == -1)
      uerror("epoll_ctl", Nothing);
    return Val_unit;
  }

  CAMLprim value poll_stub_epoll_wait(value epoll_fd, value buf, value t) {
    CAMLparam3(epoll_fd, buf, t);
    struct epoll_event *events;
    int event_count, res;
    int timeout = Long_val(t);

    events = (struct epoll_event *)Caml_ba_data_val(buf);
    event_count = Caml_ba_array_val(buf)->dim[0] / sizeof(struct epoll_event);

    caml_enter_blocking_section();
    res = epoll_wait(Long_val(epoll_fd), events, event_count, timeout);
    caml_leave_blocking_section();

    if (res == -1)
      uerror("epoll_wait", Nothing);

    CAMLreturn(Val_long(res));
  }
#else
  typedef int dummy_definition;
#endif
