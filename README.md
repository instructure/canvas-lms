Canvas LMS
======

Canvas is a modern, open-source [LMS](https://en.wikipedia.org/wiki/Learning_management_system)
developed and maintained by [Instructure Inc.](https://www.instructure.com/) It is released under the
AGPLv3 license for use by anyone interested in learning more about or using
learning management systems.

[Please see our main wiki page for more information](http://github.com/instructure/canvas-lms/wiki)

Installation
=======

Detailed instructions for installation and configuration of Canvas are provided
on our wiki.

 * [Quick Start](http://github.com/instructure/canvas-lms/wiki/Quick-Start)
 * [Production Start](http://github.com/instructure/canvas-lms/wiki/Production-Start)

## Local development with Docker

If you want to evaluate Canvas quickly, the repository includes a set of helper
`make` targets that front the docker-compose workflow. The shortest path to a running stack is:
```bash
make dev-setup    # prepares configs, copies defaults, guides you through setup
make dev          # launches the Canvas Dev Toolbox TUI (start/stop, admin helpers)
```

`make dev-setup` opens a Bubble Tea TUI wrapper around `script/docker_dev_setup.sh`
when Go is available; press `u` inside the TUI to start `docker compose up -d`, or
`d` to stop the stack without running additional Make targets. Prefer the classic
shell workflow? Use `make dev-setup-legacy`.

`make dev` launches the Canvas Dev Toolbox TUI for day-to-day tasks (start/stop
services, create admins, tail logs, switch stacks, etc.).

Additional shortcuts (admin helpers, alternate stacks, shells, etc.) are documented in [`doc/docker/README.md`](doc/docker/README.md).

## Local development without Docker

If you already have PostgreSQL, Redis, Ruby, and Node.js installed natively you
can run Canvas directly on your host machine. Start with:

```bash
make local-setup        # installs gems, node modules, and seeds the DB
make local-services     # runs Rails, webpack, and delayed_job together
```

Prefer separate terminals? You can launch individual pieces instead:

```bash
make local-server       # rails server (requires DB/Redis running locally)
make local-webpack      # rspack watcher (frontend)
make local-jobs         # delayed_job worker
```

These commands expect PostgreSQL and Redis to be reachable on their default
ports. Helpful starting points (adjust for your platform):

- macOS (Homebrew): `brew services start postgresql redis`
- Linux (systemd): `sudo systemctl start postgresql redis`
- Windows: start services from the Services control panel or `pg_ctl` /
  `redis-server` manually.

Run `make local-env-check` anytime to verify the required binaries are on your
PATH. If you later want to jump back into Docker, the compose helpers continue
to work side-by-side.

The setup command copies any missing `*.yml.example`/`*.yml.sample` files into
`config/`. Update placeholders—especially `config/database.yml` credentials—before
starting the app. The `local-services` shortcut uses `Procfile.local`, so you can
customize or extend the processes by editing that file.

## Kubernetes (Helm / Terraform)

You can run Canvas on a local Kubernetes cluster if you prefer not to use Docker.
The repo ships a dev-friendly Helm chart plus matching Terraform configuration.

### Prerequisites

- `kubectl` configured for your cluster (the examples below use [Minikube](https://minikube.sigs.k8s.io/))
- [Helm 3](https://helm.sh/docs/intro/install/)
- Optional: [Terraform 1.5+](https://developer.hashicorp.com/terraform/downloads) if you want Terraform to drive the install
- Your host kernel needs the iptables `xt_comment` match (Kconfig option `CONFIG_NETFILTER_XT_MATCH_COMMENT`, module name `xt_comment`). If `minikube start` leaves pods stuck in `ContainerCreating` with `Couldn't load match 'comment'`, load the module via `sudo modprobe xt_comment`, rebuild your kernel with that option enabled, or start Minikube with a VM driver (VirtualBox, Hyper-V, etc.) that bundles the module.

### Quick start with Minikube

1. Build the Canvas image that Kubernetes will run (the Helm chart expects `canvas-lms:latest`). Pick the Dockerfile that matches your preferred stack:

   ```bash
   # Default Ubuntu-based dev stack
   docker build -t canvas-lms:latest .
   # Arch stack (matches docker-compose.arch.yml)
   docker build -t canvas-lms:latest -f Dockerfile.arch .
   # Alpine stack (matches docker-compose.alpine.yml)
   docker build -t canvas-lms:latest -f Dockerfile.alpine .
   ```

   If you use the stack manager/select-stack TUIs to choose another base image, reuse the same Dockerfile here. To build directly inside Minikube’s Docker daemon, run `eval $(minikube docker-env)` before the `docker build` command and skip the image load in the next step.

2. Start Minikube and make the image available to the cluster:

   ```bash
   minikube start
   minikube image load canvas-lms:latest   # skip if you built inside Minikube
   ```

   Targeting a remote registry instead? Push the image there and set `image.repository` / `image.tag` via `HELM_VALUES` or `HELM_SET_ARGS` at install time.

3. Install the chart and forward port 3000 back to your workstation:

   ```bash
   make k8s-helm-install
   make k8s-port-forward
   ```

   On first boot the web container checks for the `accounts` table and, if it
   is missing, runs `bundle exec rake db:initial_setup` automatically. Set
   `CANVAS_AUTO_INITIAL_SETUP=false` if you prefer to seed the database
   manually.

Open `http://localhost:3000` in your browser and sign in with the default admin
credentials shown in the setup TUI or `values.yaml`. When you’re finished:

```bash
make k8s-helm-uninstall
```

Need to tweak the release name/namespace or install with extra values? Combine
the environment variables when you run the make target (load your custom image
first if it lives outside Minikube’s Docker daemon):

```bash
minikube image load your-registry/canvas:tag  # if you built the image elsewhere
make k8s-helm-install HELM_RELEASE=canvas HELM_NAMESPACE=canvas-dev \
  HELM_VALUES="my-overrides.yaml"
```
```

### Terraform automation (optional)

Prefer declarative infrastructure? The Terraform module under
`infra/terraform/k8s/` wraps the same Helm chart:

```bash
make k8s-apply        # terraform apply (creates the namespace if needed)
make k8s-destroy      # terraform destroy
```

You can customise release/namespace by exporting `HELM_RELEASE` and
`HELM_NAMESPACE`, or by editing `terraform.tfvars`.
