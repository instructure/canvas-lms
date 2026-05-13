# Project: Smart Due‑Date Conflict Detector — Project Issues & Stories

This file contains drafted user stories, issue bodies, milestone suggestions, dependencies, and a verification checklist derived from `implementation-research.md`.

## User Stories (title — FRs)

- Conflict detection service — FR1, FR7
  - Acceptance criteria: unit tests for single/multiple/edge cases; configurable window (default 48h); service object returns conflict sets per student.

- Background conflict job — FR7, NFR (performance)
  - Acceptance criteria: daily job + on-change triggers; completes within perf targets for 50k students; retries and emits metrics.

- Student Dashboard: conflict banner — FR2, FR4
  - Acceptance criteria: banner shown when conflicts exist; links to Conflict Details; snooze/dismiss persisted per user.

- Calendar: conflict highlighting — FR3
  - Acceptance criteria: highlights conflict days; accessible (screen reader text + non-color cues).

- Conflict Details modal (student) — FR4
  - Acceptance criteria: lists assignments, courses, suggested actions; supports snooze/dismiss; preference honored.

- Instructor analytics sidebar (aggregated) — FR5, FR8
  - Acceptance criteria: shows percent affected; respects privacy thresholds (no reporting if <5 students); no student-identifying data.

- Preferences & institution config — FR6
  - Acceptance criteria: admin-level and user-level settings persisted via API; institution overrides possible.

- Feature flag + rollout — FR9
  - Acceptance criteria: feature flag gates UI, jobs, and notifications; rollout plan documented.

- Tests & observability — NFRs
  - Acceptance criteria: unit + integration tests; metrics for job duration, conflict counts, and dismissals.

- Accessibility review — A11
  - Acceptance criteria: WCAG 2.1 AA compliance; keyboard and screen-reader verification.

## Draft GitHub Issue Payloads (titles & short bodies)

1. Conflict detection service (algorithm + service object)
   - Body: "FR: 1,7\n\nAcceptance criteria:\n- Unit tests for overlap logic\n- Configurable window (default 48h)\n- Returns conflict sets per student"
   - Labels: backend, feature

2. Background conflict job (daily + on-change)
   - Body: "FR:7\n\nAC: Job completes within perf targets; retries; emits metrics"
   - Labels: backend, job

3. Student Dashboard: conflict banner
   - Body: "FR:2,4\n\nAC: Banner, link to details, snooze/dismiss persisted"
   - Labels: ui, feature

4. Calendar: conflict highlighting
   - Body: "FR:3\n\nAC: Highlights conflict days; accessible"
   - Labels: ui, feature

5. Conflict Details modal (student)
   - Body: "FR:4\n\nAC: Lists assignments, allows snooze/dismiss; links to assignments"
   - Labels: ui, feature

6. Instructor analytics sidebar (aggregated)
   - Body: "FR:5,8\n\nAC: Aggregated counts; privacy thresholds; link to distribution view"
   - Labels: ui, feature

7. Preferences & institution config
   - Body: "FR:6\n\nAC: Admin and user-level settings persisted via API; institution overrides"
   - Labels: backend, config

8. Feature flag + rollout plan
   - Body: "FR:9\n\nAC: Flag gating; documented staged rollout steps"
   - Labels: ops, feature

9. Tests: unit & integration for conflict detector
   - Body: "NFR: testing\n\nAC: unit + integration test suite covering algorithm and UI integration"
   - Labels: tests

10. Observability: metrics & logs
   - Body: "NFR: observability\n\nAC: metrics for job duration, conflict counts, dismissals; alerting for job failures"
   - Labels: infra

11. Accessibility review & fixes
   - Body: "AC: WCAG 2.1 AA compliance for all UI components; keyboard and screen-reader passes"
   - Labels: a11y

## Milestones

- Milestone 1: Core algorithm + unit tests (Issues: 1,9)
- Milestone 2: Background job + observability (Issues: 2,10)
- Milestone 3: Student UI (banner + modal) + accessibility (Issues: 3,5,11)
- Milestone 4: Calendar highlight + instructor UI (Issues: 4,6)
- Milestone 5: Preferences, config, feature-flag rollout + integration tests (Issues: 7,8,9)

## Dependencies (high level)

- Assignments API availability → required before algorithm integration
- User preference storage → required for snooze/dismiss
- Job scheduling infra → required for background job
- Dashboard/Calendar UI wrappers → required for front-end stories

## Verification Checklist

- [ ] Project exists in `Oliphant714/canvas-lms` Projects (Projects v2)
- [ ] All drafted issues created in repo (match titles)
- [ ] Issues added to Project and assigned to milestones
- [ ] Issue dependencies linked (e.g., Background job depends on Conflict detection service)
- [ ] Mapping verified: every FR in `implementation-research.md` maps to at least one story
- [ ] Tests created and assigned to Milestone 1/2
- [ ] Accessibility review scheduled and executed

## Required GitHub Settings

- Repository issues must be enabled for `Oliphant714/canvas-lms`.
- The GitHub token used with `gh` must include Projects v2 write access.
- The user running the commands must have permission to create repository issues and organization/user projects.

## Ready-To-Run Script

Use this after enabling issues and granting the token Projects permission.

```powershell
$ErrorActionPreference = 'Stop'
$Repo = 'Oliphant714/canvas-lms'
$Owner = 'Oliphant714'
$ProjectTitle = 'Smart Due-Date Conflict Detector'

$project = gh project create --owner $Owner --title $ProjectTitle --format json | ConvertFrom-Json

function New-Issue {
   param(
      [string]$Title,
      [string]$Body,
      [string]$Labels
   )

   $url = gh issue create --repo $Repo --title $Title --body $Body --label $Labels
   return $url.Trim()
}

$issues = @()
$issues += [pscustomobject]@{ Key = 'service'; Title = 'Conflict detection service (algorithm + service object)'; Url = (New-Issue 'Conflict detection service (algorithm + service object)' "FR: 1,7`n`nAcceptance criteria:`n- Unit tests for overlap logic`n- Configurable window (default 48h)`n- Returns conflict sets per student" 'backend,feature' ) }
$issues += [pscustomobject]@{ Key = 'job'; Title = 'Background conflict job (daily + on-change)'; Url = (New-Issue 'Background conflict job (daily + on-change)' "FR:7`n`nAC: Job completes within perf targets; retries; emits metrics" 'backend,job' ) }
$issues += [pscustomobject]@{ Key = 'dashboard'; Title = 'Student Dashboard: conflict banner'; Url = (New-Issue 'Student Dashboard: conflict banner' "FR:2,4`n`nAC: Banner, link to details, snooze/dismiss persisted" 'ui,feature' ) }
$issues += [pscustomobject]@{ Key = 'calendar'; Title = 'Calendar: conflict highlighting'; Url = (New-Issue 'Calendar: conflict highlighting' "FR:3`n`nAC: Highlights conflict days; accessible" 'ui,feature' ) }
$issues += [pscustomobject]@{ Key = 'modal'; Title = 'Conflict Details modal (student)'; Url = (New-Issue 'Conflict Details modal (student)' "FR:4`n`nAC: Lists assignments, allows snooze/dismiss; links to assignments" 'ui,feature' ) }
$issues += [pscustomobject]@{ Key = 'instructor'; Title = 'Instructor analytics sidebar (aggregated)'; Url = (New-Issue 'Instructor analytics sidebar (aggregated)' "FR:5,8`n`nAC: Aggregated counts; privacy thresholds; link to distribution view" 'ui,feature' ) }
$issues += [pscustomobject]@{ Key = 'config'; Title = 'Preferences & institution config'; Url = (New-Issue 'Preferences & institution config' "FR:6`n`nAC: Admin and user-level settings persisted via API; institution overrides" 'backend,config' ) }
$issues += [pscustomobject]@{ Key = 'flag'; Title = 'Feature flag + rollout plan'; Url = (New-Issue 'Feature flag + rollout plan' "FR:9`n`nAC: Flag gating; documented staged rollout steps" 'ops,feature' ) }
$issues += [pscustomobject]@{ Key = 'tests'; Title = 'Tests: unit & integration for conflict detector'; Url = (New-Issue 'Tests: unit & integration for conflict detector' "NFR: testing`n`nAC: unit + integration test suite covering algorithm and UI integration" 'tests' ) }
$issues += [pscustomobject]@{ Key = 'obs'; Title = 'Observability: metrics & logs'; Url = (New-Issue 'Observability: metrics & logs' "NFR: observability`n`nAC: metrics for job duration, conflict counts, dismissals; alerting for job failures" 'infra' ) }
$issues += [pscustomobject]@{ Key = 'a11y'; Title = 'Accessibility review & fixes'; Url = (New-Issue 'Accessibility review & fixes' "AC: WCAG 2.1 AA compliance for all UI components; keyboard and screen-reader passes" 'a11y' ) }

foreach ($issue in $issues) {
   $issue.Number = [int](($issue.Url -split '/')[-1])
}

$byKey = @{}
foreach ($issue in $issues) {
   $byKey[$issue.Key] = $issue
}

gh issue comment $byKey.job.Number --repo $Repo --body "Depends on #$($byKey.service.Number) for conflict set computation and windowing."
gh issue comment $byKey.dashboard.Number --repo $Repo --body "Depends on #$($byKey.service.Number) and #$($byKey.config.Number) for conflict summaries and preference handling."
gh issue comment $byKey.calendar.Number --repo $Repo --body "Depends on #$($byKey.service.Number) for conflict-day calculation."
gh issue comment $byKey.modal.Number --repo $Repo --body "Depends on #$($byKey.service.Number) and #$($byKey.config.Number) for details and snooze/dismiss state."
gh issue comment $byKey.instructor.Number --repo $Repo --body "Depends on #$($byKey.service.Number) and privacy threshold logic from #$($byKey.config.Number)."
gh issue comment $byKey.tests.Number --repo $Repo --body "Covers #$($byKey.service.Number), #$($byKey.dashboard.Number), #$($byKey.calendar.Number), and #$($byKey.modal.Number)."
gh issue comment $byKey.obs.Number --repo $Repo --body "Depends on #$($byKey.job.Number) for job metrics and on #$($byKey.service.Number) for conflict counts."
gh issue comment $byKey.a11y.Number --repo $Repo --body "Depends on the UI work in #$($byKey.dashboard.Number), #$($byKey.calendar.Number), and #$($byKey.modal.Number)."

Write-Host "Project URL: $($project.url)"
Write-Host "Issue numbers: $($issues.Number -join ', ')"
```

## Next steps

- Option A: Enable repository issues and grant Projects v2 permission to the token, then run the script above.
- Option B: I can convert the script into a standalone `.ps1` file in the repository.
- Option C: I can add milestone names and dependency links into the issue bodies for a more formal launch checklist.
