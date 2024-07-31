#!/bin/bash

DEV=false
PORT=

while (( $# > 0 )); do
  case $1 in
    --dev)
      shift
      DEV=true
      ;;
    --port|-p)
      shift
      PORT=$1
      shift
      ;;
  esac
done

if ! [[ "$PORT" =~ ^[0-9]+$ ]]; then
  echo "expected numeric --port argument" >&2
  exit 1
elif ! [[ -x "./httpd.jq" ]]; then
  echo "expected to find executable ./httpd.jq" >&2
  exit 1
fi

run() {
  if $DEF; then
    echo './httpd.jq' | entr -r "$@"
  else
    "$@"
  fi
}

echo "Starting up..." >&2
run socat tcp4-listen:22222,bind=127.0.0.1,reuseaddr,fork system:'./httpd.jq'
