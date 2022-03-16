FROM docker.io/ocaml/opam:debian-11-ocaml-4.13
RUN ["/bin/bash", "-c", "sudo apt-get install -y libev-dev pkg-config libssl-dev screen libgmp-dev"]
RUN ["/bin/bash", "-c", "opam install -y dream ppx_yojson_conv cohttp-lwt-unix ppx_deriving tyxml"]
RUN ["/bin/bash", "-c", "sudo apt-get install -y libffi-dev libargon2-1"]
RUN ["/bin/bash", "-c", "opam install -y omd argon2"]
COPY --chown=opam . SiteDeClasse
WORKDIR SiteDeClasse
RUN ["/bin/bash", "-c", "eval $(opam env) && dune build"]
ENTRYPOINT ["_build/default/src/server.exe"]
