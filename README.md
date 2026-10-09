# docker-nginx-with-nodejs

An Alpine-based Nginx image with Node.js 24 LTS and npm. It is a base image for
serving static assets or building frontend assets with Node. The default
command starts **Nginx only**; run Node applications in a separate service.

| Component | Version |
| --- | --- |
| Node.js | 24.21.0 |
| npm | 11.19.0 |
| Nginx mainline | 1.31.6 |
| Alpine Linux | 3.24 |
| Supported platforms | `linux/amd64`, `linux/arm64` |

Official Node and Nginx image versions and manifest digests are pinned in
Dockerfile. Published releases do not update automatically.

## Build and run

```sh
docker build -t nginx-with-nodejs:local .
docker run --rm -p 8080:80 nginx-with-nodejs:local
curl http://localhost:8080/
docker run --rm nginx-with-nodejs:local node --version
```

Images are published to `thornwu/nginx-with-nodejs` by version-tag releases.
Use an existing explicit release tag from Docker Hub, for example
`thornwu/nginx-with-nodejs:0.3.0`. Source and releases: [thornfe/docker-nginx-with-nodejs](https://github.com/thornfe/docker-nginx-with-nodejs).
The GitHub repository owner and Docker Hub namespace are independent; the
Docker Hub image name remains unchanged for existing users. Release tags include the full
version, minor version, major version, `latest`, and a source SHA tag; minor,
major and `latest` tags can move. Pin a full version or digest for deployments.

Mount static files and HTTP configuration:

```sh
docker run --rm -p 8080:80 \
  -v "$PWD/public:/usr/share/nginx/html:ro" \
  -v "$PWD/default.conf:/etc/nginx/conf.d/default.conf:ro" \
  nginx-with-nodejs:local
```

The default process runs as root, with Nginx workers using the `nginx` user.
A `node` user (UID/GID 1000) is available for Node commands. A non-root Nginx
setup requires custom writable paths and an appropriate listen port.

## Templates and startup hooks

Mount `*.template` files into `/etc/nginx/templates`. Startup substitutes
exported environment variables and writes files into `/etc/nginx/conf.d`.
The output directory must exist and be writable; generation failures stop
startup. Nginx variables such as `$host` are preserved unless an environment
variable with the same name is selected for substitution. Prefer an explicit
filter such as `NGINX_ENVSUBST_FILTER='^(UPSTREAM_HOST|UPSTREAM_PORT)$'`.

| Variable | Default / behavior |
| --- | --- |
| `NGINX_ENVSUBST_TEMPLATE_DIR` | `/etc/nginx/templates` |
| `NGINX_ENVSUBST_TEMPLATE_SUFFIX` | `.template` |
| `NGINX_ENVSUBST_OUTPUT_DIR` | `/etc/nginx/conf.d` |
| `NGINX_ENVSUBST_FILTER` | Empty: all exported variables; otherwise an awk regular expression |
| `NGINX_ENTRYPOINT_QUIET_LOGS` | Nonempty value suppresses entrypoint logs |
| `NGINX_ENTRYPOINT_WORKER_PROCESSES_AUTOTUNE` | Nonempty value enables CPU/cgroup-aware worker tuning |
| `TZ` | Timezone, e.g. `Asia/Shanghai` |

Executable `.envsh` and `.sh` hooks in `/docker-entrypoint.d` run in version
sort order when the command is `nginx` or `nginx-debug`. `.envsh` hooks are
sourced and exports reach subsequent hooks and the final process. Hook names
may contain spaces but must not contain newlines. Failed hooks stop startup.
Other commands pass through directly. `docker stop` sends SIGQUIT for graceful
Nginx shutdown; logs go to stdout/stderr.

## Verification and maintenance

```sh
docker build --platform linux/amd64 -t nginx-with-nodejs:test .
./tests/smoke.sh nginx-with-nodejs:test linux/amd64
# Repeat with linux/arm64 on a native or emulation-enabled Docker host.
```

CI builds and runs regression/HTTP/shutdown checks on both platforms before
publishing version tags. Pull requests, main-branch pushes, and manual runs
validate only; only version-tag pushes publish. The Renovate configuration proposes Docker base
updates within Node 24; install/enable Renovate on this repository to activate
those proposals. Dependabot is configured to propose Action updates.
Review bundled versions, license texts and expected test versions with each
upgrade. See [CONTRIBUTING.md](CONTRIBUTING.md) and [SECURITY.md](SECURITY.md).

Project changes use MIT; upstream code retains its original licenses. See
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
