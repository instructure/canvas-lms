# Assignment Create/Edit Page

## Architecture

Backbone app (`EditView.jsx`) with isolated React "islands" mounted into DOM placeholders. React islands **cannot share Context** - they communicate via `postMessage` and DOM events.

> The new React-only UI (`react/index.tsx`) has **0% adoption**. All production traffic uses Backbone.

## Key Concepts

### Form Data Flow
```
Save → getFormData() → validateBeforeSave() → POST /api/v1/courses/:id/assignments
```

`getFormData()` collects data two ways:
- **Auto:** All inputs with `name` attribute (via `serializeForm`)
- **Manual:** Reads specific elements by `id` for parsing/conditional logic

**Why hidden inputs?** React islands can't directly share state with Backbone. Hidden inputs act as a bridge - React writes to the DOM element, Backbone reads from it during form submission. "Hidden" just means invisible to users (`<input type="hidden">`).

### Cross-Component Communication

React islands receive messages from Backbone via `postMessage`:
```javascript
window.top.postMessage({ subject: 'ASGMT.togglePeerReviews', enabled: false }, '*')
```

**Why `=== false`?** Messages may not always be sent. Using `!enabled` would treat `undefined` (no message) the same as `false` (explicitly disabled), causing bugs. Always use `=== false` to only act when explicitly disabled.

### Settings Dependencies

| Change | Effect |
|--------|--------|
| Grading Type → "Not Graded" | Disables peer reviews |
| Moderated Grading enabled | Disables peer reviews + group assignments |
| Group Category selected | Shows "within groups" peer review option |

### Rubrics Are Different

Rubrics use a **separate API** (`POST /api/v1/courses/:id/rubrics`), not the assignment form. No hidden inputs or `getFormData()` code needed for rubrics.

## Feature Flags (Usage %)

| Flag | Usage | Notes |
|------|-------|-------|
| `enhanced_rubrics` | **35%** | Most-used optional feature |
| `anonymous_marking` | **25%** | Anonymous grading |
| `moderated_grading` | **15%** | Disables peer reviews when on |
| `peer_review_allocation_and_grading` | **0%** | In active development |
| `assignment_edit_enhancements_teacher_view` | **0%** | New React UI - not in production |

*Source: [Canvas Feature Analytics](https://103443579803.observeinc.com/workspace/41863084/dashboard/Canvas-Feature-Analytics-Dashboard-42279288) (Jan 2026)*

## Key Files

| File | Purpose |
|------|---------|
| `backbone/views/EditView.jsx` | Main view, form handling, `getFormData()` |
| `jst/EditView.handlebars` | Form template with React mount points |
| `react/PeerReviewDetails.tsx` | Peer review settings (in development) |
| `react/ModeratedGradingFormFieldGroup.jsx` | Moderated grading UI |
| `react/AssignmentRubric.tsx` | Rubric selection (uses separate API) |

## Adding New Settings

1. Set ENV in controller: `js_env(MY_FLAG: @context.feature_enabled?(:my_flag))`
2. Create React component with hidden input: `<input type="hidden" id="my_setting_hidden" value={value} />`
3. Add mount point in `EditView.handlebars`
4. Mount from `EditView.jsx`
5. Read in `getFormData()`: `data.my_setting = document.getElementById('my_setting_hidden')?.value`

To make settings disable each other: send `postMessage` from Backbone, listen in React with `=== false` check, clear hidden input value when disabled.

## Backbone Model Methods

The Assignment model (`ui/shared/assignments/backbone/models/Assignment.js`) requires explicit method binding.

**When adding a new method:**
1. Define on prototype: `Assignment.prototype.myMethod = function() { return this.get('my_attr') }`
2. Bind in constructor: `this.myMethod = this.myMethod.bind(this)`

See existing methods like `gradingType`, `peerReviewCount` for examples.

## Known Issues

- `postMessage` uses `'*'` origin (security concern)
- No message registry - subject strings scattered in codebase
- Race conditions possible - messages can arrive before listeners attach
- **Manual state sync required** - when changing interdependent settings (grading type, peer reviews, moderated grading), code paths must: (1) update model, (2) update DOM, (3) send postMessage, (4) call render functions for affected React components. Missing any step causes bugs.
