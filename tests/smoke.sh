#!/bin/sh
set -eu
image=${1:-nginx-with-nodejs:test}
platform=${2:-linux/amd64}
test_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
container=
cleanup() {
    if [ -n "$container" ]; then docker rm -f "$container" >/dev/null 2>&1 || true; fi
}
trap cleanup EXIT HUP INT TERM
docker run --rm --platform "$platform" --entrypoint sh \
    -v "$test_dir:/tests:ro" "$image" /tests/container.sh
container=$(docker run -d --platform "$platform" --cpus=1 \
    -e NGINX_ENTRYPOINT_WORKER_PROCESSES_AUTOTUNE=1 "$image")
attempt=0
until docker exec "$container" wget -qO- http://127.0.0.1/ > /dev/null 2>&1; do
    attempt=$((attempt + 1))
    if [ "$attempt" -ge 20 ]; then docker logs "$container"; exit 1; fi
    sleep 1
done
docker exec "$container" sh -c 'wget -qO- http://127.0.0.1/ | grep -q "Welcome to nginx"; grep -Eq "^worker_processes[[:space:]]+1;" /etc/nginx/nginx.conf'
docker stop -t 10 "$container" >/dev/null
[ "$(docker inspect --format '{{.State.ExitCode}}' "$container")" = 0 ]
docker logs "$container" 2>&1 | grep -q 'gracefully shutting down'
echo "HTTP, worker autotuning and graceful stop passed ($platform)"
