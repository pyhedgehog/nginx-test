#!/bin/bash
set -eo pipefail
declare URL DEBUG QUIET NGINX_CONF NGINX_CONF_ADD
if [[ "$NGINX_CONF" = /etc/nginx/* ]] ; then
  test "${DEBUG:-0}" = 2&&declare -p URL DEBUG QUIET NGINX_CONF NGINX_CONF_ADD
elif [[ -f "$NGINX_CONF" ]] ; then
  mkdir /etc/nginx
  cp "$NGINX_CONF" /etc/nginx/nginx.conf
  test "${DEBUG:-0}" = 2&&declare -p URL DEBUG QUIET NGINX_CONF NGINX_CONF_ADD
  NGINX_CONF=/etc/nginx/nginx.conf
else
  mkdir /etc/nginx
  default_add=$'location = /_meta {\nreturn 200 "{\\"error\\": \\"No config defined.\\"}\\n";\n}'
  URL="${URL:-/_meta}"
  default=$'events{}\nhttp {\nserver\n{\nlisten 127.0.0.1:80;\nroot /usr/share/nginx/html;\n'"${NGINX_CONF_ADD:-$default_add}"$'\n}\n}'
  echo "${NGINX_CONF:-$default}" > /etc/nginx/nginx.conf
  test "${DEBUG:-0}" = 2&&declare -p URL DEBUG QUIET NGINX_CONF NGINX_CONF_ADD
  NGINX_CONF=/etc/nginx/nginx.conf
fi
test "${QUIET:-0}" = 0||exec 2>/dev/null
nginx -t -c "$NGINX_CONF" >&2 || (res=$?;cat "$NGINX_CONF";exit $res)
nginx -c "$NGINX_CONF" >&2 &chpid=$!
sleep 0
test "${DEBUG:-0}" = 2&&set -x
if [[ $# = 0 ]] ; then
  set -- "${URL:-/}"
fi
if [[ $# = 1 && "$1" = /* ]] ; then
  set -- -sS "$1"
fi
if [[ $# = 2 && "$2" = /* ]] ; then
  set -- "$1" "http://127.0.0.1$2"
fi
test "${DEBUG:-0}" = 0||set -x
curl "$@"
test "${DEBUG:-0}" = 2||set +x
nginx -s stop
wait "$chpid"
