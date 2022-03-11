#!/bin/sh

pgrep -x server.exe >/dev/null && killall server.exe
dune build
./_build/default/src/server.exe &

while true; do 
    inotifywait src static -e modify -qq; 
    pgrep -x server.exe >/dev/null && killall server.exe
    dune build
    ./_build/default/src/server.exe &
done
