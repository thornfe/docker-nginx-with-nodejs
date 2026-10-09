#!/bin/sh
set -eu
node -e 'if (process.version !== "v24.21.0") process.exit(1)'
[ "$(npm --version)" = '11.19.0' ]
nginx -v 2>&1 | grep -F 'nginx/1.31.6'
nginx -t
[ -s /usr/share/licenses/nginx-with-nodejs/third-party/node-LICENSE.txt ]
[ -s /usr/share/licenses/nginx-with-nodejs/third-party/nginx-LICENSE.txt ]
[ -s /usr/share/licenses/nginx-with-nodejs/third-party/npm-LICENSE.txt ]

# Source hooks must export variables into both later hooks and the main process.
printf 'export REVIEW_VALUE=from_hook\n' > '/docker-entrypoint.d/05-test export.envsh'
printf '#!/bin/sh\ncat > /dev/null\n[ "$REVIEW_VALUE" = from_hook ]\n' > /docker-entrypoint.d/06-test.sh
chmod +x '/docker-entrypoint.d/05-test export.envsh' /docker-entrypoint.d/06-test.sh
mkdir /tmp/test-bin
cat > /tmp/test-bin/nginx <<'SH'
#!/bin/sh
[ "$REVIEW_VALUE" = from_hook ]
printf "%s" "$REVIEW_VALUE" > /tmp/main-process-value
SH
chmod +x /tmp/test-bin/nginx
# The inherited resolver hook resets PATH; restore the test stub afterwards.
printf 'export PATH=/tmp/test-bin:$PATH\n' > /docker-entrypoint.d/99-test-path.envsh
chmod +x /docker-entrypoint.d/99-test-path.envsh
PATH=/tmp/test-bin:$PATH /docker-entrypoint.sh nginx
[ "$(cat /tmp/main-process-value)" = from_hook ]
rm /tmp/main-process-value

# A failing hook must prevent the main process from starting.
printf '#!/bin/sh\nexit 42\n' > /docker-entrypoint.d/07-fail.sh
chmod +x /docker-entrypoint.d/07-fail.sh
if PATH=/tmp/test-bin:$PATH /docker-entrypoint.sh nginx; then
    echo 'Failing hook was ignored' >&2
    exit 1
else
    [ "$?" -eq 42 ]
fi
[ ! -e /tmp/main-process-value ]
rm /docker-entrypoint.d/07-fail.sh

mkdir -p /tmp/templates/nested /tmp/output
printf 'value=${REVIEW_VALUE}; nginx=$host; slash=${SLASH_VALUE}\n' > /tmp/templates/nested/test.conf.template
export REVIEW_VALUE=from_environment SLASH_VALUE=matched
NGINX_ENVSUBST_TEMPLATE_DIR=/tmp/templates NGINX_ENVSUBST_OUTPUT_DIR=/tmp/output \
    NGINX_ENVSUBST_FILTER='^REVIEW_VALUE$' /docker-entrypoint.d/20-envsubst-on-templates.sh
[ "$(cat /tmp/output/nested/test.conf)" = 'value=from_environment; nginx=$host; slash=${SLASH_VALUE}' ]
# A slash in the filter is a regex literal, not interpolated awk source.
NGINX_ENVSUBST_TEMPLATE_DIR=/tmp/templates NGINX_ENVSUBST_OUTPUT_DIR=/tmp/output \
    NGINX_ENVSUBST_FILTER='SLASH_VALUE|NO/MATCH' /docker-entrypoint.d/20-envsubst-on-templates.sh
[ "$(cat /tmp/output/nested/test.conf)" = 'value=${REVIEW_VALUE}; nginx=$host; slash=matched' ]
if NGINX_ENVSUBST_TEMPLATE_DIR=/tmp/templates NGINX_ENVSUBST_OUTPUT_DIR=/missing-output \
    /docker-entrypoint.d/20-envsubst-on-templates.sh; then
    echo 'Template output failure was ignored' >&2
    exit 1
fi
if NGINX_ENVSUBST_TEMPLATE_DIR=/tmp/templates NGINX_ENVSUBST_OUTPUT_DIR=/tmp/output \
    NGINX_ENVSUBST_FILTER='[' /docker-entrypoint.d/20-envsubst-on-templates.sh; then
    echo 'Invalid template filter was ignored' >&2
    exit 1
fi
# Direct Node commands should pass through unchanged.
/docker-entrypoint.sh node -e 'console.log("Node command passthrough OK")'
# Verify a sourced export reaches a real template and real Nginx response.
rm /docker-entrypoint.d/99-test-path.envsh
mkdir -p /etc/nginx/templates
cat > /etc/nginx/templates/regression.conf.template <<'CONF'
server {
    listen 8081;
    location / { return 200 "${REVIEW_VALUE}"; }
}
CONF
/docker-entrypoint.sh nginx -g 'daemon off;' > /tmp/template-nginx.log 2>&1 &
nginx_pid=$!
trap 'kill -QUIT "$nginx_pid" 2>/dev/null || true' EXIT HUP INT TERM
attempt=0
until wget -qO- http://127.0.0.1:8081/ > /tmp/template-response 2>/dev/null; do
    attempt=$((attempt + 1))
    if [ "$attempt" -ge 20 ]; then cat /tmp/template-nginx.log; exit 1; fi
    sleep 1
done
[ "$(cat /tmp/template-response)" = from_hook ]
kill -QUIT "$nginx_pid"
wait "$nginx_pid"
trap - EXIT HUP INT TERM
echo 'Container regression and template HTTP checks passed'
