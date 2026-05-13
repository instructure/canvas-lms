# AWS + Canvas LMS Runbook

**Goal**: Use AI assistance to launch Canvas LMS development stack on AWS EC2 Learner Lab instance.  
**Status**: Ready for execution  
**Last Updated**: 2026-05-13

---

## Part A: AI Prompts Used (Summary)

### Prompt 1: Learner Lab + EC2 Setup

```
You are helping set up a Canvas LMS development environment on AWS.

Step 1: Launch AWS Academy Learner Lab
- Activate the lab environment
- Wait for credentials to be issued
- Download or note the EC2 key pair (.pem file)

Step 2: Create or verify EC2 instance
- Ensure t3.large or larger instance is running (Canvas needs 2+ GB RAM)
- Use Amazon Linux 2 or Ubuntu 20.04 LTS
- Enable SSH access from my IP: allow port 22 inbound
- Tag the instance "canvas-lms-dev" for easy identification

Step 3: Connect via SSH
- Use remote SSH in VS Code or terminal
- Connection string: ssh -i /path/to/key.pem ec2-user@<instance-ip> (Amazon Linux 2)
  or ubuntu@<instance-ip> (Ubuntu)

Output for me:
- Instance ID (pattern: i-0xxxxxxxxx)
- Public IP address
- Confirmation that SSH port 22 is reachable
```

### Prompt 2: Docker and Dependencies on EC2

```
On the EC2 instance, prepare the Canvas LMS environment:

Step 1: Install system dependencies
- Docker and Docker Compose (latest versions)
- Git
- Node.js LTS (v18 or v20)
- Ruby 3.1 or 3.2 (Canvas requirement)
- PostgreSQL client (psql binary)

Step 2: Clone Canvas LMS repository
- Clone your fork: git clone https://github.com/YOUR_USERNAME/canvas-lms.git
- cd canvas-lms
- Verify repo structure: ls -la | grep -E "docker-compose|Gemfile|package.json"

Step 3: Initialize Docker volumes
- Ensure Docker daemon is running: sudo systemctl start docker
- Build Canvas containers: docker compose build (or docker-compose build if using older version)

Output for me:
- Confirmation of all installed versions
- Canvas repo cloned successfully
- Docker daemon status: running
```

### Prompt 3: Start Canvas Development Stack

```
In the Canvas LMS repository on your EC2 instance, start the development stack:

Step 1: Bring up containers
- Run: docker compose up -d
- Wait 30-60 seconds for services to initialize
- Check status: docker compose ps

Step 2: Initialize database
- Run: docker compose run --rm web bundle exec rake db:create
- Run: docker compose run --rm web bundle exec rake db:migrate
- Run: docker compose run --rm web bundle exec rake db:seed (optional, for test data)

Step 3: Verify Canvas is running
- Check port 3000: curl http://localhost:3000/health_check
- Expected response: "Canvas is OK" (HTTP 200)
- If port 3000 not exposed, check: docker compose logs web | tail -20

Output for me:
- docker compose ps output (all containers running)
- Database initialization completion messages
- Health check response from Canvas
```

---

## Part B: Learner Lab + EC2 Checklist

Use this checklist alongside the AWS Academy Learner Lab console:

### Lab Activation
- [ ] Log into AWS Academy Learner Lab
- [ ] Click "Start Lab" button
- [ ] Wait for status indicator to turn green (connection available)
- [ ] Note the countdown timer for lab access (typically 4 hours)

### EC2 Instance Setup
- [ ] Instance type selected: **t3.large** (minimum for Canvas)
  - 2 vCPUs, 8 GB memory, 20+ GB storage recommended
- [ ] Image: **Amazon Linux 2** or **Ubuntu 20.04 LTS**
- [ ] Security group inbound rules:
  - [ ] SSH (port 22) from your IP (0.0.0.0/0 for testing, restrict in production)
  - [ ] HTTP (port 80) from 0.0.0.0/0 (optional, for testing)
  - [ ] Custom (port 3000) from 0.0.0.0/0 (Canvas dev server)
- [ ] Key pair: Downloaded and stored securely (~/.ssh/canvas-dev.pem)
- [ ] Instance launched and running (green status in EC2 console)

### SSH Access Verification
- [ ] SSH connection successful: `ssh -i ~/.ssh/canvas-dev.pem ec2-user@<ip>`
- [ ] Can list files on EC2: `ls /home/ec2-user`
- [ ] Can run commands: `uname -a` returns Linux kernel info
- [ ] Optional: Add instance to VS Code Remote-SSH config

### System Dependencies on EC2
- [ ] Docker installed: `docker --version` → Docker version 20.10+
- [ ] Docker Compose installed: `docker compose version` → v2.0+
- [ ] Git installed: `git --version` → git 2.30+
- [ ] Node.js installed: `node --version` → v18+ LTS
- [ ] Ruby installed: `ruby --version` → 3.1.x or 3.2.x
- [ ] PostgreSQL client: `psql --version` → psql 12+
- [ ] Storage available: `df -h /` → 20+ GB free recommended

---

## Part C: Canvas LMS Clone + Doc Path Followed

### Official References

Canvas LMS upstream documentation used for this setup:

| Document | Path | Purpose |
|---|---|---|
| Quick Start | [github.com/instructure/canvas-lms/wiki/Quick-Start](https://github.com/instructure/canvas-lms/wiki/Quick-Start) | Official getting started guide |
| Docker Setup | [doc/docker/README.md](../../doc/docker/README.md) in repo | Docker Compose configuration |
| Install Guide | [doc/api/README.md](../../doc/api/README.md) (development section) | Development environment setup |
| Repository Structure | [AGENTS.md](../AGENTS.md) (this fork) | Canvas LMS project layout |

### Clone Steps

```bash
# On your local machine, fork Canvas LMS (if you haven't already)
# https://github.com/instructure/canvas-lms/fork

# SSH into EC2 instance
ssh -i ~/.ssh/canvas-dev.pem ec2-user@<instance-ip>

# Clone your fork on the instance
cd /home/ec2-user
git clone https://github.com/YOUR_USERNAME/canvas-lms.git
cd canvas-lms

# Verify structure (should match upstream canvas-lms)
ls -la | head -20
# Expected output: docker-compose.yml, Gemfile, package.json, app/, ui/, etc.

# Verify this is a Canvas LMS fork
grep -i "canvas" README.md | head -5
```

### Documentation Path Followed

1. **Quick Start** → Official setup steps from Canvas wiki
2. **docker-compose.yml** → Defined services (web, postgres, redis, etc.)
3. **Gemfile** → Ruby dependencies (Rails, Canvas plugins)
4. **package.json** → JavaScript/Node dependencies (React, webpack, yarn)
5. **doc/docker/** → Docker-specific configuration and troubleshooting
6. **[AGENTS.md](../AGENTS.md)** → Quick reference for Canvas structure

---

## Part D: Verification Commands and Signals

### Command 1: Check Docker Compose Services

**Command**:
```bash
docker compose ps
```

**Expected Output**:
```
NAME        IMAGE              COMMAND                 STATUS
web         canvas_web         "bundle exec puma..."   Up
postgres    postgres:15        "docker-entrypoint..."  Up
redis       redis:7            "redis-server..."       Up
```

**Signal Canvas is working**: All services showing "Up" status, no error states  
**Troubleshoot**: If any service is "Exit" or "Exited", check logs: `docker compose logs <service>`

---

### Command 2: Check Canvas Health Endpoint

**Command**:
```bash
curl http://localhost:3000/health_check
```

**Expected Output**:
```
Canvas is OK
```

**Signal Canvas is working**: HTTP 200 response with "Canvas is OK" message  
**Troubleshoot**: 
- If connection refused, Canvas web container may not be fully initialized (wait 30-60s)
- If "Connection refused" persists, check: `docker compose logs web | tail -50`
- If port 3000 not accessible, verify security group allows port 3000 inbound

---

### Command 3: Check Rails Database Migrations

**Command**:
```bash
docker compose exec web bundle exec rake db:migrate:status | head -20
```

**Expected Output**:
```
database: canvas_development

 Status   Migration ID    Migration Name
--------------------------------------------------
   up     20220101000001  CreateInitialTables
   up     20220102000002  CreateUsers
   ...
```

**Signal Canvas is working**: Migrations showing "up" status, no pending migrations  
**Troubleshoot**: If you see "down" migrations, run: `docker compose exec web bundle exec rake db:migrate`

---

### Command 4: Check Canvas Web Logs for Errors

**Command**:
```bash
docker compose logs web | grep -E "ERROR|WARN" | tail -10
```

**Expected Output**:
```
(Empty or only deprecation warnings, no fatal errors)
```

**Signal Canvas is working**: No ERROR lines, or only expected warnings  
**Troubleshoot**: Presence of ERROR lines suggests database issues, missing dependencies, or configuration problems

---

### Command 5: Access Canvas Web Interface (Local Development)

**Via browser on EC2 or forwarded**:
```bash
# If running locally: http://localhost:3000
# If running on EC2: ssh tunnel to forward port 3000
ssh -i ~/.ssh/canvas-dev.pem -L 3000:localhost:3000 ec2-user@<instance-ip>
# Then open: http://localhost:3000 in your browser
```

**Expected signals**:
- Canvas login page loads (may show brand/theme)
- No JavaScript errors in browser console (F12 → Console tab)
- "Unauthorized" or login prompt appears (Canvas is responding to web requests)

---

### Command 6: Verify Database Connection

**Command**:
```bash
docker compose exec web bundle exec rails c
```

**Once in Rails console, run**:
```ruby
irb(main):001:0> Account.count
=> 1
irb(main):002:0> User.count
=> 0
irb(main):003:0> exit
```

**Expected Output**:
- Account count ≥ 1 (root account created by default)
- User count may be 0 (seeding is optional)

**Signal Canvas is working**: No ActiveRecord errors, database queries succeed  
**Troubleshoot**: If you get "connection refused", database container is not running or not initialized

---

## Part E: Troubleshooting Common Issues

| Issue | Diagnosis | Resolution |
|---|---|---|
| `docker compose up` hangs or times out | Check Docker daemon status | Run `sudo systemctl status docker`; if stopped, run `sudo systemctl start docker` |
| "Postgres connection refused" | Database container crashed | Check: `docker compose logs postgres` |
| Port 3000 connection refused | Canvas web not ready or crashed | Wait 60s, then check: `docker compose logs web` |
| Database migrations fail | Schema mismatch or corrupt DB | Run: `docker compose down -v` (removes volumes), then `docker compose up` |
| "Gem not found" error in web logs | Bundler cache stale | Run: `docker compose run --rm web bundle install` |
| Webpack/JS assets not building | Node dependencies missing | Run: `docker compose run --rm web yarn install` |

---

## Part F: Next Steps (Out of Scope: Feature Implementation)

**Lab 3.1 ends here.** The following are **Lab 4** tasks and explicitly **out of scope**:

- [ ] Implement a Canvas feature (e.g., new API endpoint, React component, plugin)
- [ ] Write tests for the feature (RSpec, Jest, Vitest)
- [ ] Deploy the feature to production or staging
- [ ] Integrate with external Canvas plugins or LTI tools

**Lab 4 kickoff will assume**:
- Canvas development stack is running on AWS EC2
- All verification commands above pass
- Your fork is up-to-date with upstream Canvas LMS
- You have documented any custom configuration (environment variables, database seeds, etc.)

---

## Verification Checklist (Final Sign-Off)

Use this checklist to confirm Canvas is working before Lab 4:

- [ ] EC2 instance running and SSH accessible
- [ ] `docker compose ps` shows all services "Up"
- [ ] `curl http://localhost:3000/health_check` returns "Canvas is OK"
- [ ] `docker compose exec web bundle exec rake db:migrate:status` shows all migrations "up"
- [ ] Rails console (`docker compose exec web bundle exec rails c`) can query Account/User models
- [ ] Canvas login page accessible at http://localhost:3000 (or via SSH tunnel)
- [ ] No ERROR lines in `docker compose logs web`
- [ ] Disk space available on EC2: `df -h /` shows 10+ GB free

**When all boxes are checked**: Canvas is ready for Lab 4 feature development.

---

## Appendix: Quick Reference Commands

```bash
# Container management
docker compose up -d                           # Start services in background
docker compose down                            # Stop and remove containers
docker compose down -v                         # Also remove volumes (WARNING: deletes DB)
docker compose ps                              # List running services
docker compose logs <service>                  # View logs for a service
docker compose exec web bash                   # Shell into web container

# Database
docker compose exec web bundle exec rake db:create              # Create database
docker compose exec web bundle exec rake db:migrate             # Run migrations
docker compose exec web bundle exec rake db:seed                # Seed test data
docker compose exec web bundle exec rails c                    # Rails console

# Building and assets
docker compose run --rm web yarn install                        # Install JS dependencies
docker compose run --rm web bundle install                      # Install Ruby gems
docker compose run --rm web yarn build                          # Build frontend

# Verification
curl http://localhost:3000/health_check                         # Health check
curl http://localhost:3000/api/v1/courses                       # API call (requires auth)
```

---

## Document Metadata

**Created**: 2026-05-13  
**Last Updated**: 2026-05-13  
**Status**: Ready for execution  
**References**:
- [Canvas LMS Upstream](https://github.com/instructure/canvas-lms)
- [Quick Start Wiki](https://github.com/instructure/canvas-lms/wiki/Quick-Start)
- [AGENTS.md](../AGENTS.md) (this fork)
- AWS Academy Learner Lab documentation (per instructor)
