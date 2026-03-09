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

---

## Core West Alexa Integration

This repository includes a voice briefing plugin for the **Core West Command Center** that integrates with Amazon Alexa.

**Location:** [`plugins/corewest_alexa/`](plugins/corewest_alexa/)

The plugin is a self-contained FastAPI service that:

- Handles Alexa skill webhook requests (`POST /alexa/webhook`)
- Returns voice-friendly summaries for inspection readiness, teacher metrics, student risk, tasks, and incidents (`GET /alexa/query`)
- Exposes a structured JSON dashboard endpoint (`GET /alexa/dashboard`)
- Pulls live data from the Canvas LMS REST API with graceful fallback to mock data

### Quick Start

```bash
cd plugins/corewest_alexa
pip install -r requirements.txt
uvicorn main:app --reload
```

For Docker setup and full documentation, see [`plugins/corewest_alexa/README.md`](plugins/corewest_alexa/README.md).
