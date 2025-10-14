# Using Docker to run Canvas

_*Instructure employees should use the `inst` CLI. Go [here](./../../inst-cli/doc/docker/developing_with_docker.md) for more info.*_

## Prerequisites

You need Docker. Don't have Docker yet? Go [here](getting_docker.md) for details on getting it setup.

## Development

Just on Linux (skip this on OSX), you may want to run this to avoid a few
permissions issues first by granting Canvas docker containers write access to
your Canvas folder:

```bash
setfacl -Rm u:9999:rwX,g:9999:rwX .
setfacl -dRm u:9999:rwX,g:9999:rwX .
sudo addgroup --gid 9999 docker-instructure
sudo usermod -a -G docker-instructure $USER
```

After logging back into your system (to recognize your new group), you should be
able to edit or delete any files created by Canvas docker containers. If you're
using this approach to grant Canvas write access, you can also disable the
default built-in usermod hack that runs Canvas containers as your host UID
instead (since this has been known to cause problems). This can be done by
adding this to your `~/.bash_profile`:

```bash
export CANVAS_SKIP_DOCKER_USERMOD=1
```

For everyone now, this command should get you going:

```bash
make dev-setup
```

Don’t have `make` handy? The original command still works:

```bash
./script/docker_dev_setup.sh
```

`make dev-setup` now launches an interactive Bubble Tea interface (requires Go on
your PATH). When the script finishes, press `u` to start `docker compose up -d`
or `d` to stop containers without running additional make targets. Use
`make dev-setup-legacy` to run the plain shell workflow.

Prefer to drive everything through one entry point? The repository now includes a
`Makefile` with helpful wrappers. Run `make help` to see the available targets;
common ones are `make dev-up` (foreground) or `make dev-up-detached` followed by
`make dev-logs` to tail output.

Other handy shortcuts:

- `make dev-shell` opens a bash shell in the web container (use `SERVICE=jobs`
  to pick a different service).
- `make dev-admin EMAIL=you@example.com PASSWORD=Secret123!` provisions an
  administrator account without navigating the rake tasks manually.

Be sure to pay attention to any `Next Steps` output from the script that you may need to run.

Now you can do `make dev-up-detached` (or `docker compose up -d`) and you should be good to go. If you're
using Dinghy-http-proxy or Dory you should be able to access Canvas by going to: [http://canvas.docker/](http://canvas.docker/)

For more information checkout [Developing with Docker](developing_with_docker.md)

### Alternative base images

The generated `docker-compose.yml` continues to use our Ubuntu-based image, but
the repo now ships experimental Arch and Alpine variants for developers who
want to exercise different toolchains:

- `docker-compose -f docker-compose.arch.yml up` builds from `Dockerfile.arch`
  and reproduces an Arch Linux environment with a source-built Ruby. The helper
  shorthand is `make dev-up STACK=arch`.
- `docker-compose -f docker-compose.alpine.yml up` builds from
  `Dockerfile.alpine` and provides a musl-based Alpine stack while preserving
  the same entrypoint behaviour. The helper shorthand is
  `make dev-up STACK=alpine`.

Both stacks share the same bind mounts and entry scripts as the default
configuration, so you can switch between them without changing app state. These
images are community-maintained; expect to make adjustments as rolling releases
update compilers and system packages.

### Managed encryption keys

If you don’t provide `ENCRYPTION_KEY` (or `JWT_ENCRYPTION_KEY`) when using the
Arch or Alpine stacks, the entrypoint now generates secure random values and
persists them under `tmp/docker-secrets/` inside the project volume. The files
are shared across services, so the generated keys survive container restarts.
Set the variables yourself if you prefer to manage secrets manually. When a new
key is minted the entrypoint also exports `UPDATE_ENCRYPTION_KEY_HASH=1` so the
database hash refreshes automatically during boot.

### Webpack warm-up

The web container now waits (up to `CANVAS_WEBPACK_BOOT_TIMEOUT`, default 120s)
for `public/dist/webpack-dev/mf-manifest.json` to appear before starting Puma.
This avoids 404s for hashed bundles when the Alpine/Arch webpack watcher is
still finishing its first compile. Set `CANVAS_SKIP_WEBPACK_WAIT=1` if you’d
prefer the old behaviour.

## Known Issues

### Long URL Gateway 502

If a URL is long enough, you may see a Gateway 502 error. This problem
has been patched in [dinghy-http-proxy#36](https://github.com/codekitchen/dinghy-http-proxy/pull/36)
however until a new release is cut the follow can be done as a work
around:

In `~/.dinghy/proxy.conf` add the following:

    proxy_buffers 8 1024k;
    proxy_buffer_size 1024k;

Restart dinghy afterwards.

### `EMFILE: too many open files`

When the Arch compose stack brings up `webpack` and Rails simultaneously the
frontend build can open thousands of files in bursts (for i18n extraction, code
generation, etc.). Previously this required cranking `ulimit -n` inside the
containers. We now preload [`graceful-fs`](https://github.com/isaacs/node-graceful-fs)
from the Arch entrypoint so Node queues new reads instead of crashing, and we
retry synchronous filesystem calls with a small backoff to smooth out `EMFILE`
spikes. If you override `NODE_OPTIONS` for custom dev scripts make sure to
preserve the default `--require /usr/src/app/config/node/setup-graceful-fs.cjs`
flag so the guard stays active.

The backoff can be tuned with the following environment variables if your host
needs longer pauses before descriptor churn subsides:

- `CANVAS_EMFILE_RETRY_DELAY_MS` (default `25`)
- `CANVAS_EMFILE_MAX_RETRY_DELAY_MS` (default `1000`)
- `CANVAS_EMFILE_RETRY_TIMEOUT_MS` (default `300000`)
- `CANVAS_EMFILE_MAX_INFLIGHT` (default `256`) to limit how many filesystem
  operations the JS toolchain issues concurrently; lower it if your host still
  reports `EMFILE` while the caches warm up
- `CANVAS_EMFILE_DEBUG` (default `false`) to log retry attempts and active
  handle counts when diagnosing stubborn `EMFILE` spikes

The Arch and Alpine `docker-compose.*.yml` files enable `CANVAS_EMFILE_DEBUG=1`
so you can capture retry telemetry out of the box; export
`CANVAS_EMFILE_DEBUG=0` if you want to silence the additional logging.
