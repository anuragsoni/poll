(lang dune 2.9)

(name poll)

(generate_opam_files true)

(source
 (github anuragsoni/poll))

(authors "Anurag Soni")

(maintainers "Anurag Soni <anurag@sonianurag.com>")

(documentation https://anuragsoni.github.io/poll)

(license MIT)

(package
 (name poll)
 (synopsis "Portable OCaml interface to macOS/Linux/Windows native IO event notification mechanisms")
 (description
  "poll provides a portable OCaml interface to IO event notification mechanisms on macOS, Linux and Windows. It uses kqueue on macOS, epoll on Linux, and uses a vendored copy of wepoll on Windows.")
 (tags
  (epoll kqueue wepoll))
 (depends
  base-unix
  ppx_optcomp
  (kqueue
   (>= 0.2.0))
  dune-configurator
  (ppx_expect :with-test)
  (ppx_optcomp :with-test)
  (ocaml
   (>= 4.13))))
