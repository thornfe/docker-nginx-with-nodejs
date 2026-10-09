# Official images use the same musl/Alpine baseline on both supported platforms.
FROM node:24.21.0-alpine3.24@sha256:ebfe2f90462722a7a4de65e91990e97fe0d401c70e0e762c5b53302f905ec1c1 AS node
FROM nginx:1.31.6-alpine3.24-slim@sha256:f761b94f2cb9e8e05e2943d5f773609596113ef69b54e2433a996d109a8f78b7

ENV NODE_VERSION=24.21.0
LABEL org.opencontainers.image.source="https://github.com/thornfe/docker-nginx-with-nodejs" \
      org.opencontainers.image.licenses="MIT AND BSD-2-Clause"

COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules/npm /usr/local/lib/node_modules/npm
COPY --from=node /usr/local/include/node /usr/local/include/node
RUN apk add --no-cache libstdc++ ca-certificates \
    && addgroup -g 1000 node \
    && adduser -u 1000 -G node -s /bin/sh -D node \
    && ln -s node /usr/local/bin/nodejs \
    && ln -s ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && ln -s ../lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx \
    && node --version && npm --version && nginx -t

COPY --chmod=755 docker-entrypoint.sh /
COPY --chmod=755 10-listen-on-ipv6-by-default.sh 20-envsubst-on-templates.sh 30-tune-worker-processes.sh /docker-entrypoint.d/
COPY LICENSE THIRD_PARTY_NOTICES.md /usr/share/licenses/nginx-with-nodejs/
COPY licenses/ /usr/share/licenses/nginx-with-nodejs/third-party/

ENTRYPOINT ["/docker-entrypoint.sh"]
EXPOSE 80
STOPSIGNAL SIGQUIT
CMD ["nginx", "-g", "daemon off;"]
