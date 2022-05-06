# Poll

Portable OCaml library to poll for I/O readiness events. All I/O events are oneshot, and on delivery
of an I/O readiness event we need to re-register interest in the event if we need a notification of
the next event of the same kind.

This library currently supports the following platforms:

* macOS via [kqueue](https://en.wikipedia.org/wiki/Kqueue)
* Linux via [epoll](https://en.wikipedia.org/wiki/Epoll)
* Windows via [wepoll](https://github.com/piscisaureus/wepoll)
