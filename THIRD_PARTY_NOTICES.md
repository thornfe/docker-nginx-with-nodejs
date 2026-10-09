# Third-party notices

Project-authored changes are MIT licensed; the repository LICENSE does not
replace licenses for upstream code or bundled software.

| Component | Source/version | License text |
| --- | --- | --- |
| Copied Nginx Docker entrypoint and hooks | nginx/docker-nginx, original commit `5ce65c3efd395ee2d82d32670f233140e92dba99`; locally modified | `licenses/nginx-docker.BSD-2-Clause.txt` |
| Historical Node Docker installation recipe | nodejs/docker-node, original commit `cd7015f45666d2cd6e81f507ee362ca7ada1bfee` | `licenses/node-docker.MIT.txt` |
| Node.js runtime and headers | 24.21.0, from the official Node Docker image | `licenses/node-LICENSE.txt`, including bundled dependency notices |
| npm | 11.19.0, from the official Node Docker image | `licenses/npm-LICENSE.txt` and package notices in `/usr/local/lib/node_modules/npm` |
| Nginx | 1.31.6, from the official Nginx Docker image | `licenses/nginx-LICENSE.txt` |

The exact official image digests are recorded in Dockerfile. Alpine packages
retain their respective licenses; inspect package metadata with `apk info`.
Project and third-party notices are included in the image under
`/usr/share/licenses/nginx-with-nodejs`. When upgrading bundled versions,
refresh their license texts as well as version references and checks.
