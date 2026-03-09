/**
 * Core West College — Main JavaScript
 * Self-contained, no external dependencies
 */

/* ── Hamburger / Mobile Nav Toggle ─────────────────────────────── */
(function initNav() {
  const hamburger = document.querySelector('.hamburger');
  const body = document.body;
  const dropdowns = document.querySelectorAll('.dropdown');

  if (hamburger) {
    hamburger.addEventListener('click', () => {
      body.classList.toggle('nav-open');
      hamburger.setAttribute('aria-expanded', body.classList.contains('nav-open'));
    });

    // Close nav when clicking outside
    document.addEventListener('click', (e) => {
      if (!e.target.closest('.navbar') && body.classList.contains('nav-open')) {
        body.classList.remove('nav-open');
      }
    });
  }

  // Mobile: tap dropdown toggle
  dropdowns.forEach((dd) => {
    const link = dd.querySelector('.nav-link');
    if (link) {
      link.addEventListener('click', (e) => {
        if (window.innerWidth <= 992) {
          e.preventDefault();
          dd.classList.toggle('open');
        }
      });
    }
  });
})();

/* ── Sticky Navbar Scroll Behavior ─────────────────────────────── */
(function initScrollBehavior() {
  const navbar = document.querySelector('.navbar');
  if (!navbar) return;

  const onScroll = () => {
    navbar.classList.toggle('scrolled', window.scrollY > 20);
  };

  window.addEventListener('scroll', onScroll, { passive: true });
  onScroll();
})();

/* ── Smooth Scrolling for Anchor Links ─────────────────────────── */
(function initSmoothScroll() {
  document.querySelectorAll('a[href^="#"]').forEach((anchor) => {
    anchor.addEventListener('click', (e) => {
      const target = document.querySelector(anchor.getAttribute('href'));
      if (target) {
        e.preventDefault();
        target.scrollIntoView({ behavior: 'smooth', block: 'start' });
      }
    });
  });
})();

/* ── Active Nav Link Highlighting ──────────────────────────────── */
(function initActiveNav() {
  const currentPath = window.location.pathname;
  document.querySelectorAll('.nav-link').forEach((link) => {
    const href = link.getAttribute('href');
    if (href && (href === currentPath || (href !== '/' && currentPath.startsWith(href)))) {
      link.classList.add('active');
    }
  });
})();

/* ── Animated Number Counters (IntersectionObserver) ───────────── */
(function initCounters() {
  const counters = document.querySelectorAll('[data-counter]');
  if (!counters.length) return;

  const easeOutQuad = (t) => t * (2 - t);

  const animateCounter = (el) => {
    const target = parseFloat(el.dataset.counter);
    const suffix = el.dataset.suffix || '';
    const duration = parseInt(el.dataset.duration || '2000', 10);
    const startTime = performance.now();

    const step = (now) => {
      const elapsed = now - startTime;
      const progress = Math.min(elapsed / duration, 1);
      const eased = easeOutQuad(progress);
      const current = Math.round(eased * target);
      el.textContent = current.toLocaleString() + suffix;
      if (progress < 1) requestAnimationFrame(step);
    };
    requestAnimationFrame(step);
  };

  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting && !entry.target.dataset.animated) {
          entry.target.dataset.animated = 'true';
          animateCounter(entry.target);
        }
      });
    },
    { threshold: 0.3 }
  );

  counters.forEach((el) => observer.observe(el));
})();

/* ── Contact Form Validation ────────────────────────────────────── */
(function initContactForm() {
  const form = document.getElementById('contact-form');
  if (!form) return;

  const showError = (input, msg) => {
    let err = input.parentElement.querySelector('.form-error');
    if (!err) {
      err = document.createElement('span');
      err.className = 'form-error';
      input.parentElement.appendChild(err);
    }
    err.textContent = msg;
    input.classList.add('error');
  };

  const clearError = (input) => {
    const err = input.parentElement.querySelector('.form-error');
    if (err) err.textContent = '';
    input.classList.remove('error');
  };

  const isValidEmail = (email) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);

  form.addEventListener('submit', (e) => {
    e.preventDefault();
    let valid = true;

    form.querySelectorAll('[required]').forEach((input) => {
      clearError(input);
      if (!input.value.trim()) {
        showError(input, 'This field is required.');
        valid = false;
      } else if (input.type === 'email' && !isValidEmail(input.value.trim())) {
        showError(input, 'Please enter a valid email address.');
        valid = false;
      }
    });

    if (valid) {
      const btn = form.querySelector('[type="submit"]');
      btn.textContent = '✅ Message Sent!';
      btn.disabled = true;
      setTimeout(() => {
        form.reset();
        btn.textContent = 'Send Message';
        btn.disabled = false;
      }, 3000);
    }
  });

  // Live clearing
  form.querySelectorAll('input, textarea, select').forEach((input) => {
    input.addEventListener('input', () => clearError(input));
  });
})();

/* ── Login Form Handling ────────────────────────────────────────── */
(function initLoginForm() {
  const form = document.getElementById('login-form');
  if (!form) return;

  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    const username = form.querySelector('#username')?.value.trim();
    const password = form.querySelector('#password')?.value.trim();
    const btn = form.querySelector('[type="submit"]');
    const errEl = document.getElementById('login-error');

    if (!username || !password) {
      if (errEl) errEl.textContent = 'Please enter your username and password.';
      return;
    }

    btn.textContent = 'Signing in…';
    btn.disabled = true;

    try {
      const res = await fetch('/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, password }),
      });

      if (res.ok) {
        const data = await res.json();
        if (data.token) localStorage.setItem('cwc_jwt', data.token);
        window.location.href = '/dashboard';
      } else {
        if (errEl) errEl.textContent = 'Invalid credentials. Please try again.';
        btn.textContent = 'Sign In';
        btn.disabled = false;
      }
    } catch {
      // Fallback: demo login for offline/dev
      if (username === 'admin' && password === 'admin') {
        localStorage.setItem('cwc_jwt', 'demo-token');
        window.location.href = '/dashboard';
      } else {
        if (errEl) errEl.textContent = 'Unable to connect. Please try again.';
        btn.textContent = 'Sign In';
        btn.disabled = false;
      }
    }
  });
})();

/* ── Dashboard Data Loading ─────────────────────────────────────── */
(function initDashboard() {
  if (!document.body.classList.contains('dashboard-page')) return;

  const mockStats = {
    inspection_readiness: 78,
    curriculum_coverage: 85,
    teachers: 52,
    students: 487,
    open_tasks: 14,
    incidents: 3,
  };

  const applyStats = (stats) => {
    const map = {
      '#stat-inspection':  stats.inspection_readiness + '%',
      '#stat-curriculum':  stats.curriculum_coverage + '%',
      '#stat-teachers':    stats.teachers,
      '#stat-students':    stats.students,
      '#stat-tasks':       stats.open_tasks,
      '#stat-incidents':   stats.incidents,
    };
    Object.entries(map).forEach(([sel, val]) => {
      const el = document.querySelector(sel);
      if (el) el.textContent = val;
    });

    // Circular gauge
    const fill = document.querySelector('.gauge-fill');
    if (fill) {
      const circumference = 339.3;
      const pct = stats.inspection_readiness / 100;
      fill.style.strokeDashoffset = circumference * (1 - pct);
    }

    // Progress bars
    document.querySelectorAll('[data-progress]').forEach((bar) => {
      const key = bar.dataset.progress;
      if (stats[key] !== undefined) bar.style.width = stats[key] + '%';
    });
  };

  fetch('/api/stats')
    .then((r) => r.json())
    .then(applyStats)
    .catch(() => applyStats(mockStats));
})();

/* ── Newsletter Form ────────────────────────────────────────────── */
(function initNewsletter() {
  document.querySelectorAll('.newsletter-form').forEach((form) => {
    form.addEventListener('submit', (e) => {
      e.preventDefault();
      const input = form.querySelector('input[type="email"]');
      const btn = form.querySelector('button');
      if (input && input.value.trim()) {
        btn.textContent = '✅ Subscribed!';
        input.value = '';
        btn.disabled = true;
        setTimeout(() => {
          btn.textContent = 'Subscribe';
          btn.disabled = false;
        }, 4000);
      }
    });
  });
})();

/* ── Tab Component ──────────────────────────────────────────────── */
(function initTabs() {
  document.querySelectorAll('.tabs').forEach((tabGroup) => {
    tabGroup.querySelectorAll('.tab-btn').forEach((btn) => {
      btn.addEventListener('click', () => {
        const target = btn.dataset.tab;
        const parent = tabGroup.closest('.tab-container') || document;

        tabGroup.querySelectorAll('.tab-btn').forEach((b) => b.classList.remove('active'));
        btn.classList.add('active');

        parent.querySelectorAll('.tab-panel').forEach((panel) => {
          panel.classList.toggle('active', panel.dataset.panel === target);
        });
      });
    });
  });
})();

/* ── Set Current Date (Dashboard) ──────────────────────────────── */
(function setCurrentDate() {
  const el = document.getElementById('current-date');
  if (!el) return;
  const now = new Date();
  el.textContent = now.toLocaleDateString('en-GB', {
    weekday: 'long', year: 'numeric', month: 'long', day: 'numeric',
  });
})();
