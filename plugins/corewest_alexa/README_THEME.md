# Core West College — Frontend Theme Plugin

A branded frontend theme for the **Core West College AI LMS**, built as a self-contained FastAPI plugin with Jinja2 templates, custom CSS, and vanilla JavaScript. No external CDN dependencies.

---

## Theme Overview

| Item | Detail |
|------|--------|
| **School** | Core West College |
| **Location** | 1st Neighborhood, District 13, El Sheikh Zayed, Egypt |
| **Chairman & CEO** | Mr. Mahmoud Gohar (BBA, MBA) |
| **Head of Schools** | Mrs. Shereen Moussad (20+ yrs American & British) |
| **Divisions** | International Early Years · American · British · National |
| **Framework** | FastAPI + Jinja2 |
| **Styling** | Custom CSS (no Bootstrap/Tailwind) |
| **JS** | Vanilla JS (no React/Vue/jQuery) |

---

## Colour Scheme

| Variable | Hex | Usage |
|----------|-----|-------|
| `--color-navy-dark` | `#1a237e` | Primary brand, headers, CTAs |
| `--color-navy-medium` | `#003366` | Backgrounds, text |
| `--color-navy-light` | `#1565c0` | Accents, links, progress bars |
| `--color-gold-bright` | `#ffd700` | Primary accent, buttons, borders |
| `--color-gold-muted` | `#d4a017` | Hover states, secondary accents |
| `--color-gold-dark` | `#b8860b` | Dark gold accents |
| `--color-white` | `#ffffff` | Backgrounds, text on dark |
| `--color-gray-light` | `#f5f5f5` | Section backgrounds |
| `--color-text-dark` | `#333333` | Body text |
| `--color-success` | `#2e7d32` | Success states, badges |
| `--color-warning` | `#f57f17` | Warnings, attention items |
| `--color-danger` | `#c62828` | Errors, critical alerts |

---

## File Structure

```
plugins/corewest_alexa/
├── templates/
│   ├── base.html               # Shared layout (nav, footer)
│   ├── index.html              # Homepage with hero, divisions, stats
│   ├── about.html              # About page — leadership bios
│   ├── divisions.html          # All 4 academic divisions
│   ├── teaching_learning.html  # Pedagogy and frameworks
│   ├── facilities.html         # Campus facilities grid
│   ├── admission.html          # Admission process + documents
│   ├── events.html             # School events calendar
│   ├── careers.html            # Job vacancies
│   ├── contact.html            # Contact form + map
│   ├── login.html              # Standalone admin login page
│   ├── dashboard.html          # AI Command Center (standalone)
│   ├── inspection_dashboard.html  # Ofsted/Cognia readiness (standalone)
│   └── curriculum_dashboard.html  # Curriculum coverage (standalone)
├── static/
│   ├── css/
│   │   └── style.css           # ~600-line comprehensive stylesheet
│   └── js/
│       └── main.js             # ~280-line vanilla JS
├── theme_routes.py             # FastAPI router for all HTML pages
├── main.py                     # FastAPI app entry point
└── README_THEME.md             # This file
```

---

## URL Routes

| URL | Template | Description |
|-----|----------|-------------|
| `/` | `index.html` | Homepage |
| `/about` | `about.html` | About Us |
| `/divisions` | `divisions.html` | Academic Divisions |
| `/teaching-learning` | `teaching_learning.html` | Teaching & Learning |
| `/facilities` | `facilities.html` | Campus Facilities |
| `/admission` | `admission.html` | Admissions |
| `/events` | `events.html` | Events & Activities |
| `/careers` | `careers.html` | Careers |
| `/contact` | `contact.html` | Contact Us |
| `/login` | `login.html` | Admin Login (standalone) |
| `/dashboard` | `dashboard.html` | AI Command Center (standalone) |
| `/inspection-dashboard` | `inspection_dashboard.html` | Inspection Readiness |
| `/curriculum-dashboard` | `curriculum_dashboard.html` | Curriculum Report |
| `/health` | — | JSON health check endpoint |
| `/static/*` | — | Static assets (CSS, JS) |

---

## How to Run Locally

### Prerequisites

```bash
pip install fastapi uvicorn jinja2 python-multipart aiofiles
```

### Start the Server

```bash
cd plugins/corewest_alexa
uvicorn main:app --reload --port 8000
```

Then open: [http://localhost:8000](http://localhost:8000)

---

## How to Customise

### Changing Colours

Edit the CSS custom properties at the top of `static/css/style.css`:

```css
:root {
  --color-navy-dark:   #1a237e;   /* Change brand navy */
  --color-gold-bright: #ffd700;   /* Change brand gold */
  /* ... */
}
```

### Changing Contact Information

Update the following in `templates/base.html`:
- Top bar: phone numbers, email, hours
- Footer column 3: full contact details

And in `templates/contact.html`:
- Contact cards section
- Contact form action email (mailto: links)

### Changing School Name / Leadership

- Edit `templates/base.html` (navbar brand, footer)
- Edit `templates/about.html` (Chairman & Head of Schools bios)
- Edit `templates/index.html` (hero heading, welcome message)

### Adding a New Page

1. Create `templates/my_page.html` extending base.html:
   ```html
   {% extends "base.html" %}
   {% block content %}
   <!-- your content -->
   {% endblock %}
   ```
2. Add a route in `theme_routes.py`:
   ```python
   @router.get("/my-page", response_class=HTMLResponse)
   async def my_page(request: Request):
       return render(request, "my_page.html", page_title="My Page")
   ```
3. Add a nav link in `base.html` if needed.

---

## Template Inheritance

Pages that use the full site layout (navbar + footer) extend `base.html`:

```html
{% extends "base.html" %}
{% block content %}
  <!-- page content here -->
{% endblock %}
```

**Standalone pages** (no nav/footer) have their own complete HTML structure:
- `login.html`
- `dashboard.html`
- `inspection_dashboard.html`
- `curriculum_dashboard.html`

---

## JavaScript Features

| Feature | How It Works |
|---------|-------------|
| Mobile nav toggle | Adds `.nav-open` to `<body>`, CSS handles the panel |
| Sticky navbar | Adds `.scrolled` class on scroll > 20px |
| Smooth scroll | `scrollIntoView({ behavior: 'smooth' })` for `#anchor` links |
| Counter animation | `IntersectionObserver` + `requestAnimationFrame` easing |
| Active nav links | Compares `window.location.pathname` to `href` attributes |
| Contact form validation | Required fields + email regex, inline error messages |
| Login form | POSTs to `/auth/login`, stores JWT in `localStorage`, falls back to demo mode |
| Dashboard data | Fetches `/api/stats`, falls back to mock data on error |
| Newsletter | Submission confirmation with auto-reset |
| Tab component | `.tabs` + `.tab-btn[data-tab]` + `.tab-panel[data-panel]` |

---

## Responsive Breakpoints

| Breakpoint | Behaviour |
|------------|-----------|
| `> 1200px` | Full desktop layout, 4-column grids |
| `≤ 1200px` | Tighter nav spacing, 2-column footer |
| `≤ 992px` | Mobile hamburger nav, 2-column grids |
| `≤ 768px` | Single column, stacked cards, simplified top bar |
| `≤ 576px` | Compact sections, single column throughout |

---

## Integration Notes

### Authentication

The `/login` page POSTs credentials to `/auth/login`. The backend should return:
```json
{ "token": "your-jwt-token-here" }
```
The token is stored in `localStorage` as `cwc_jwt`. Implement token validation in your FastAPI middleware or dependencies.

### Dashboard API

The dashboard fetches `/api/stats` and expects:
```json
{
  "inspection_readiness": 78,
  "curriculum_coverage": 85,
  "teachers": 52,
  "students": 487,
  "open_tasks": 14,
  "incidents": 3
}
```
If the endpoint is unavailable, mock data is used automatically.

### Static Files

Served via FastAPI's `StaticFiles` mount at `/static`. In production, consider serving via nginx or a CDN for better performance.

---

## Contact

- **General:** info@corewestcollege.com
- **Admissions:** admission@corewestcollege.com
- **HR:** hr@corewestcollege.com
- **Phone:** 01201022222 | 01210211111
- **Hours:** Sunday – Thursday, 08:00 AM – 03:00 PM
