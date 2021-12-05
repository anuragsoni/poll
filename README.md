# Poll

Portable OCaml library to poll for I/O readiness events. All I/O events are level triggered.

This library currently aims to support the following platforms:

* macOS via [kqueue](https://en.wikipedia.org/wiki/Kqueue)
* Linux via [epoll](https://en.wikipedia.org/wiki/Epoll)
* Windows via [wepoll](https://github.com/piscisaureus/wepoll)
