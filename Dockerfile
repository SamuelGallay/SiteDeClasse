FROM docker.io/ocaml/opam:debian-11-ocaml-4.12
RUN ["/bin/bash", "-c", "sudo apt-get install -y libev-dev pkg-config libssl-dev screen"]
RUN ["/bin/bash", "-c", "opam install -y dream"]
COPY --chown=opam . SiteDeClasse
WORKDIR SiteDeClasse
RUN ["/bin/bash", "-c", "eval $(opam env) && dune build"]
ENTRYPOINT ["/home/opam/SiteDeClasse/_build/default/server.exe"]
