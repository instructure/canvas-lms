# 🎓 Core West College AI LMS

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![Built on Canvas LMS](https://img.shields.io/badge/Built%20on-Canvas%20LMS-E66000.svg)](https://github.com/instructure/canvas-lms)
[![Ruby on Rails](https://img.shields.io/badge/Ruby%20on%20Rails-CC0000.svg?logo=ruby-on-rails&logoColor=white)](https://rubyonrails.org/)

> An AI-enhanced, open-source Learning Management System tailored for **Core West College** — empowering students, instructors, and administrators with modern digital education tools.

---

## 📖 What is this?

**Core West College AI LMS** is a customized deployment of [Canvas LMS](https://github.com/instructure/canvas-lms) — the industry-leading open-source Learning Management System developed by [Instructure, Inc.](https://www.instructure.com/) — enhanced with AI-assisted learning features and configured specifically for Core West College.

It provides a single, unified platform where students can access course materials, submit assignments, and track their progress, while instructors manage courses and grades, and administrators oversee the entire institution — all through a clean, mobile-friendly web interface.

---

## ✨ Key Features

| Feature | Description |
|---|---|
| 📚 **Course Management** | Create, organize, and publish courses with rich multimedia content |
| 🎓 **Student Enrollment & Grading** | Enroll students, manage cohorts, and maintain a full gradebook |
| 📝 **Assignments, Quizzes & Discussions** | Deliver assessments and foster collaborative learning |
| 🤖 **AI-Assisted Learning Tools** | Intelligent recommendations, voice briefings, and data-driven insights |
| 📱 **Mobile-Friendly Interface** | Fully responsive design accessible on any device |
| 🔗 **Integrations (LTI & APIs)** | Connect third-party tools via LTI standards and a robust REST/GraphQL API |
| 🔐 **Role-Based Access Control** | Granular permissions for students, instructors, and administrators |
| 📊 **Analytics & Reporting** | Track engagement, identify at-risk students, and measure outcomes |

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Backend** | Ruby on Rails |
| **Database** | PostgreSQL |
| **Frontend** | React · JavaScript · Webpack |
| **Containerization** | Docker · Docker Compose |
| **APIs** | REST · GraphQL · LTI 1.3 |
| **AI Integration** | FastAPI · Amazon Alexa Skill |

---

## 🚀 Getting Started

> **Prerequisites:** [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/install/) must be installed.

```bash
# 1. Clone the repository
git clone https://github.com/AbuRashad/Core-West-College-AI-lms.git
cd Core-West-College-AI-lms

# 2. Start all services
docker compose up

# 3. Open a development shell (in a separate terminal)
docker compose run --rm web bash

# 4. Set up the database (inside the dev shell)
bundle exec rake db:create db:migrate db:seed

# 5. Build frontend assets
yarn build
```

Once running, navigate to **http://localhost:3000** in your browser.

For full production deployment instructions, refer to the [Canvas LMS Production Start guide](https://github.com/instructure/canvas-lms/wiki/Production-Start).

---

### 🔊 Alexa Voice Integration (Core West Command Center)

This repository also includes a voice briefing plugin for the **Core West Command Center** that integrates with Amazon Alexa, providing hands-free access to:

- Inspection readiness status
- Teacher performance metrics
- At-risk student summaries
- Task and incident reports

```bash
cd plugins/corewest_alexa
pip install -r requirements.txt
uvicorn main:app --reload
```

See [`plugins/corewest_alexa/README.md`](plugins/corewest_alexa/README.md) for full documentation.

---

## 🔗 Repository

**GitHub:** https://github.com/AbuRashad/Core-West-College-AI-lms

---

## 📄 License

This project is licensed under the **GNU Affero General Public License v3.0**.
See the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgements

Built on [Canvas LMS](https://github.com/instructure/canvas-lms) — the open-source LMS developed and maintained by [Instructure, Inc.](https://www.instructure.com/), released under AGPLv3.

We are grateful to the entire Canvas open-source community for their continued contributions.
