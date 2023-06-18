#!/bin/sh

pgrep -x server.exe >/dev/null && killall server.exe
dune build
OCAMLRUNPARAM=b ./_build/default/src/server.exe &

while true; do 
    inotifywait src -e modify -qq; 
    pgrep -x server.exe >/dev/null && killall server.exe
    dune build
    OCAMLRUNPARAM=b ./_build/default/src/server.exe &
done
