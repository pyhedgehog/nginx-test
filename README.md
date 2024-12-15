# nginx-test

This docker image intended to check URLs agains nginx config.

## Install

Install:
```console
$ docker build -t nginx-test .
```

Check:
```console
$ docker run --rm -e DEBUG=0 -e QUIET=1 nginx-test|jq
{
  "error": "No config defined."
}
```

## Usage

Everything passed using variables:

 - `$DEBUG` - level of debug:
   - `-e DEBUG=1` - trace curl call. This is default.
   - `-e DEBUG=2` - trace nginx start and curl call.
   - `-e DEBUG=0` - trace nothing
 - `$QUIET` - if `-e QUIET=1` all stderr output hidden.
 - `$NGINX_CONF_ADD` - used only if `$NGINX_CONF` not passed. Will be wrapped with readable default context.
 - `$NGINX_CONF` - config to use:
   - raw config string - will be written to `/etc/nginx/nginx.conf` and used there.
   - path to file somewhere (use run `--volume` option) - will be copied to `/etc/nginx/nginx.conf` and used there.
   - path inside `/etc/nginx/` - will be used in place.

### Usage 1

You can only define NGINX_CONF_ADD with content of server clause and some reasonable default context will be wrapped around:

```console
$ docker run --rm \
> -e NGINX_CONF_ADD=$'location / {\nreturn 200 "{\\"data\\":\\"Something returned.\\",\\"uri\\":\\"$uri\\"}\\n";\n}' \
> nginx-test /any|jq
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
+ curl -sS http://127.0.0.1/any
127.0.0.1 - - [15/Dec/2024:06:02:30 +0000] "GET /any HTTP/1.1" 200 44 "-" "curl/7.88.1"
+ test 1 = 2
+ set +x
2024/12/15 06:02:30 [notice] 14#14: signal process started
{
  "data": "Something returned.",
  "uri": "/any"
}
```

As you can see all logging sent to stderr so you can pass output to parsing (`jq` in this case).

### Usage 2

You can define NGINX_CONF as content of config file:

```console
$ cat nginx.conf
events{}
http {
server
{
listen 127.0.0.1:80;
root /usr/share/nginx/html;
location / {
return 200 "{\"data\":\"Something returned.\",\"uri\":\"$uri\"}\n";
}
}
}
$ docker run --rm -e QUIET=1 -e NGINX_CONF="$(<nginx.conf)" nginx-test
{"data":"Something returned.","uri":"/_meta"}
```

BTW: This is exactly how your `$NGINX_CONF_ADD` from previoud example will be wrapped.

### Usage 3

You can define NGINX_CONF as path to config file (inside container):

```console
$ docker run --rm -e QUIET=1 -v $PWD/nginx.conf:/tmp/nginx.conf -e NGINX_CONF=/tmp/nginx.conf nginx-test
{"data":"Something returned.","uri":"/_meta"}
```

NB: This exact form (with `$PWD`) can be used only if you are using your local dockerd, because volume left parameter (before `:`) is path on dockerd host server.
