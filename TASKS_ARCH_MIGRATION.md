# Canvas Arch Migration: Work Breakdown

This document tracks the tasks required to bring the Canvas Docker stack to an Arch Linux base. It starts by decomposing the existing Ubuntu image so we know exactly what we must replace.

## 1. Inventory Current Runtime
- [ ] Pull `instructure/ruby-passenger:$RUBY-jammy` locally and run `docker history` / `docker inspect` to list installed packages.
- [ ] Extract `/etc/` configs (nginx, passenger, logrotate, supervisor) and their custom entrypoints.
- [ ] Document environment variables and default commands.

## 2. Build Arch Runtime Prototype
- [ ] Port package list to pacman equivalents (nginx, passenger or alternative, locale setup).
- [ ] Compile or install Passenger compatible with Arch's Ruby (3.4.0).
- [ ] Rebuild entrypoint script to launch nginx/passenger under Arch.
- [ ] Add healthcheck scripts matching upstream behavior.

## 3. Integrate Into Compose Stack
- [ ] Update `Dockerfile.arch` with runtime components.
- [ ] Adjust compose overrides to expose required ports and volumes.
- [ ] Ensure user UID/gid handling matches existing volume expectations.

## 4. Bootstrap & Validate
- [ ] Run `script/docker_dev_setup.sh` end-to-end.
- [ ] Verify asset compilation, Rails boot, and frontend builds.
- [ ] Run representative RSpec and JS test suites.
- [ ] Manual smoke: login, dashboard, LTI frame, file uploads.

## 5. Documentation & Adoption Plan
- [ ] Update `doc/docker/README.md` with Arch instructions.
- [ ] Decide whether to offer Arch alongside Ubuntu or as replacement.
- [ ] Communicate changes to contributors.

> **Note:** Each checklist item likely spans multiple commits; this document is a tracker, not a prescription for a single change.
