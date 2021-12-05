#include "config.h"

#if defined(POLL_CONF_WIN32)
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
#include "wepoll.h"


#define Epoll_constant(name, i)                                                \
    CAMLprim value name(value unit) { return Val_int(i); }

  Epoll_constant(poll_stub_epollin, EPOLLIN)
  Epoll_constant(poll_stub_epollrdhup, EPOLLRDHUP)
  Epoll_constant(poll_stub_epollhup, EPOLLHUP)
  Epoll_constant(poll_stub_epollerr, EPOLLERR)
  Epoll_constant(poll_stub_epollpri, EPOLLPRI)
  Epoll_constant(poll_stub_epollout, EPOLLOUT)


CAMLprim value poll_stub_wepoll_create1(value unit) {
    CAMLparam1(unit);
    HANDLE fd;

    fd = epoll_create1(0);
    if (fd == INVALID_HANDLE_VALUE) {
        win32_maperr(GetLastError());
        uerror("epoll_create1", Nothing);
    }
    CAMLreturn(win_alloc_handle(fd));
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
    evt.data.fd = Socket_val(fd);
    if (epoll_ctl(Handle_val(epoll_fd), operation, Socket_val(fd), &evt) == -1)
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
    if (epoll_ctl(Handle_val(epoll_fd), EPOLL_CTL_DEL, Socket_val(fd), NULL) == -1)
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
    res = epoll_wait(Handle_val(epoll_fd), events, event_count, timeout);
    caml_leave_blocking_section();

    if (res == -1)
      uerror("epoll_wait", Nothing);

    CAMLreturn(Val_long(res));
}

CAMLprim value poll_stub_epoll_iter_ready(value events, value event_len, value callback) {
    CAMLparam3(events, event_len, callback);
    struct epoll_event *epoll_events;
    epoll_events = (struct epoll_event *)Caml_ba_data_val(events);

    for (int i = 0; i < Long_val(event_len); i++) {
        caml_callback2(callback, win_alloc_socket(epoll_events[i].data.fd), Val_int(epoll_events[i].events));
    }
    CAMLreturn(Val_unit);
}
#else
  typedef int dummy_definition_wepoll;
#endif
