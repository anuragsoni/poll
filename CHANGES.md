# 0.2.0

* Use oneshot mode for events
  - Oneshot mode causes the event to return only the first time.

# 0.1.0

* Initial release
  - Supports a polling api using the platform event notification mechanisms on macOS (Kqueue), Linux (Epoll) and windows (wepoll - an epoll emulation using IOCP).
