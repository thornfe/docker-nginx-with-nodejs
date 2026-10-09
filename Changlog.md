# 0.3.1 - 2026-10-09
- Inherit IPv6 and worker hooks directly from the pinned official Nginx image.
- Sync the template hook to the image's upstream commit, including stream templates.
- Preserve local failure handling and add real stream proxy checks.

# 0.3.0 - 2026-10-09
- Upgrade to Node.js 24.21.0, npm 11.19.0, Nginx mainline 1.31.6 and Alpine 3.24.
- Use digest-pinned official images for AMD64 and ARM64.
- Preserve sourced startup exports and fail on template output errors.
- Treat envsubst filters as regex data, including filters containing slashes, and reject invalid regexes.
- Add container regression, HTTP, CPU tuning and graceful shutdown checks before publication.
- Restore upstream notices and document usage, contribution and security policy.

# 0.2.0
- Fix Nginx shell permission.
### Environment
- NODE_VERSION：18.14.2
- NGINX_VERSION：1.23.3

# 0.1.0
### Environment
- NODE_VERSION：18.14.2
- NGINX_VERSION：1.23.3
