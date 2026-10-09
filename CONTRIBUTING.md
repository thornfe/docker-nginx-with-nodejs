# Contributing

Open an issue describing the expected behavior and a minimal reproduction, or
submit a focused pull request. Keep startup and command passthrough compatible.

Build the image and run `tests/smoke.sh` for AMD64 and ARM64 as shown in README.
Changes to startup behavior should include a regression check. Version upgrades
must update pinned official image digests, runtime checks, README, changelog,
and bundled license texts together. Do not weaken download or signature checks.

Version tags use `vMAJOR.MINOR.PATCH`; pushing a tag triggers Docker Hub
publication after checks pass. Maintainers configure `DOCKERHUB_USERNAME` and
`DOCKERHUB_TOKEN` as repository secrets. Never include credentials in issues,
images, build arguments, or committed files.
