# Smart Due‑Date Conflict Detector — implementation‑research.md

## 1. Feature summary and scope
The Smart Due‑Date Conflict Detector adds automated detection of assignment clusters that create unreasonable workload spikes for students. When two or more major assignments are due within a short window (e.g., 24–48 hours), Canvas alerts the student and optionally notifies instructors.  
This expands the existing To‑Do list and Calendar without altering grading, submissions, or course‑level assignment creation.

**In scope**
- Detecting conflicts across all active courses for a student  
- Student‑visible warnings in Dashboard, Calendar, and To‑Do  
- Instructor‑visible analytics showing when their assignment contributes to a conflict  
- Notification preferences per user  
- Background job to compute conflicts daily or on assignment changes  

**Out of scope**
- Automatically changing due dates  
- Predicting assignment difficulty via ML  
- Editing assignments across courses  
- Cross‑institution data sharing  

---

## 2. Design considerations

### User flows
**Student flow**
1. Student logs in → Dashboard loads weekly tasks.  
2. Conflict detector checks the student’s assignments for overlapping due windows.  
3. If conflicts exist, the student sees:  
   - A banner on Dashboard  
   - Highlighted dates on Calendar  
   - A “Conflict Details” modal listing assignments, courses, and suggested actions  
4. Student may dismiss or snooze warnings.

**Instructor flow**
1. Instructor creates or edits an assignment.  
2. Conflict detector runs a lightweight check for students enrolled in the course.  
3. Instructor sees:  
   - A sidebar indicator: “This due date overlaps with X other major assignments for Y% of your students.”  
   - A link to view conflict distribution.

### Data crossing boundaries
- **Assignments API**: due dates, course IDs, submission types  
- **Enrollment API**: which students belong to which courses  
- **User Preferences**: notification settings  
- **Background Jobs**: conflict computation  
- **Permissions**: instructors may see aggregated conflict data but not other instructors’ assignments in detail

### UX risks
- Over‑alerting students → alert fatigue  
- Instructors feeling “judged” → must present data neutrally  
- Conflicts must be explainable and transparent (no black‑box logic)

### Interaction with existing Canvas concepts
- **Courses**: conflict detection spans all active enrollments  
- **Assignments**: uses existing due_at fields; no schema changes required  
- **Roles**: students receive personalized alerts; instructors receive aggregated analytics  
- **Calendar**: conflict highlighting overlays existing events  

### Project planning elements for Lab 4 automation
- Milestones: conflict algorithm, student UI, instructor UI, background job, notifications  
- Tasks: API integration, React components, tests, accessibility review  
- Dependencies: assignments API availability, job scheduling, user preference storage  
- Definition of done: all functional requirements satisfied, tests passing, feature flag enabled  

---

## 3. Functional requirements (testable)

1. **The system shall detect assignment conflicts** when two or more assignments for a student have due dates within a configurable time window (default: 48 hours).  
2. **The system shall display a conflict warning** on the student Dashboard when at least one conflict exists.  
3. **The system shall highlight conflict days** on the Calendar view for affected students.  
4. **The system shall allow students to dismiss or snooze conflict warnings**, and the system shall respect these preferences.  
5. **The system shall notify instructors** when their assignment contributes to a conflict affecting ≥20% of enrolled students.  
6. **The system shall allow institutions to configure the conflict window**, thresholds, and notification rules.  
7. **The system shall compute conflicts automatically** when assignments are created, updated, or deleted.  
8. **The system shall not expose student‑specific data to instructors**, only aggregated counts.  
9. **The system shall operate under a feature flag**, defaulting to off.

---

## 4. Non‑functional requirements

### Performance
- Conflict computation must complete within **<200ms per student** when triggered by assignment changes.  
- Background job must complete within **5 minutes** for institutions with up to 50k students.  
- UI rendering must not add more than **20ms** to Dashboard load time.

### Security & privacy (FERPA‑aligned)
- No cross‑course student data is exposed to instructors.  
- Aggregated analytics must use thresholds to prevent re‑identification (e.g., no reporting if <5 students affected).  
- Conflict data stored only as ephemeral computation results, not long‑term logs.

### Accessibility
- Conflict indicators must meet WCAG 2.1 AA contrast requirements.  
- Screen readers must announce conflict warnings clearly.  
- Calendar highlighting must not rely solely on color.

### Observability
- Metrics: number of conflicts detected, job duration, alert dismissals, instructor view usage.  
- Logs: assignment change events, job failures, notification dispatch.  
- Alerts: job failures, unusually high conflict rates.

### Reliability
- Background job retries on failure.  
- Feature flag allows safe rollout.  
- Graceful degradation: if conflict computation fails, Canvas continues functioning normally.

### Compatibility
- Must work with existing Canvas deployment assumptions (Ruby on Rails backend, React front‑end, Sidekiq‑style jobs).  
- No schema migrations required.

---

## 5. Codebase analysis (from Lab 2 agent workflow)

### Hypotheses about where changes will land
- **Backend (Ruby on Rails)**  
  - `app/models/assignment.rb` — due date logic  
  - `app/services/` — conflict detection service object  
  - `app/jobs/` — background job for conflict computation  
  - `app/controllers/api/v1/assignments_controller.rb` — exposing conflict metadata  

- **Frontend (React)**  
  - `ui/features/dashboard/` — student conflict banner  
  - `ui/features/calendar/` — conflict highlighting  
  - `ui/features/assignments/` — instructor conflict sidebar  

- **APIs**  
  - Extend assignments API to include conflict metadata  
  - Add new endpoint: `/api/v1/conflicts/:user_id`

### Concrete findings from agent-assisted exploration

- Assignments are stored in `app/models/assignment.rb` with fields `due_at`, `course_id`, and `submission_types`.  
- Canvas uses **service objects** in `app/services/` for cross‑model logic; conflict detection fits this pattern.  
- Background jobs use `Delayed::Job` or Sidekiq‑style wrappers in `app/jobs/`.  
- Dashboard React components live under `ui/features/dashboard/` and already consume assignment summaries.  
- Calendar events are rendered via `ui/features/calendar/react_calendar/`, which supports overlays.  
- User preferences are stored via `UserPreference` model and exposed through `/api/v1/users/:id/preferences`.

### Open questions
- Should conflict detection run synchronously on assignment creation, or only via background job?  
- Should institutions be able to override the conflict window per course?  
- How should conflicts be displayed in mobile apps (not in scope for Lab 2.1 but relevant later)?  
- Should Canvas allow instructors to preview conflicts before publishing an assignment?

---

## 6. Testing and verification plan

### Unit tests
- Conflict detection algorithm:  
  - Single conflict detection  
  - Multiple overlapping conflicts  
  - No conflicts  
  - Edge cases (assignments exactly 48 hours apart)  
- User preference handling (dismiss, snooze)  
- Instructor aggregation logic (thresholds, privacy rules)

### Integration tests
- Assignment creation → conflict computation → API returns conflict metadata  
- Dashboard loads → conflict banner appears  
- Calendar loads → conflict highlighting appears  
- Instructor assignment edit → conflict sidebar updates

### Manual / exploratory tests
- Student enrolled in multiple courses with overlapping assignments  
- Student with no conflicts  
- Instructor with small vs large classes  
- Feature flag toggling  
- Accessibility checks (screen reader, keyboard navigation)

### Acceptance criteria (mapped to functional requirements)
- AC1: When two assignments are due within 48 hours, the student sees a conflict warning (FR1, FR2).  
- AC2: Calendar highlights conflict days (FR3).  
- AC3: Student can dismiss/snooze warnings (FR4).  
- AC4: Instructor sees aggregated conflict impact (FR5).  
- AC5: Conflict detection updates automatically on assignment changes (FR7).  
- AC6: No student‑specific data leaks to instructors (FR8).  
- AC7: Feature flag controls visibility (FR9).

### When automated testing is impractical
- Instructor perception and UX clarity → addressed via manual review  
- Large‑scale performance → validated via staging environment load tests  
- Cross‑course institutional policies → validated via configuration testing

---