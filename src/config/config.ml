module C = Configurator.V1

let () =
  C.main ~name:"poll.config" (fun conf ->
      let platform =
        C.C_define.import
          conf
          ~includes:[]
          [ "linux", C.C_define.Type.Switch; "_WIN32", C.C_define.Type.Switch ]
      in
      let vars =
        [ "POLL_CONF_LINUX", List.assoc "linux" platform
        ; "POLL_CONF_WIN32", List.assoc "_WIN32" platform
        ]
      in
      C.C_define.gen_header_file conf ~fname:"config.h" vars)
;;
