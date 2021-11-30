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
 (synopsis "Portable api for polling file descriptors for IO readiness.")
 (tags (epoll kqueue))
 (depends
  ppx_optcomp
  (kqueue (>= 0.2.0))
  dune-configurator
  duration
  (ppx_expect :with-test)
  (ocaml
   (>= 4.12))))
