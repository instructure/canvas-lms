# LTI Asset Processor

## Asset Reports usage in Canvas
As of September 2025, Asset Reports (LTI Asset Processor storage) are shown in 6 places, listed below.

Paths below are relative to `canvas-lms` or `canvas-lms/ui/shared/lti-asset-processor`

### New Speedgrader
* separate repo. See `dependenciesShims.ts`

### Old Speedgrader
* Frontend:
  1. Non-AP, non-React `ui/features/speed_grader/jquery/speed_grader.tsx` renders
  2. AP component `LtiAssetReportsForSpeedgraderWrapper.tsx`

* See also `dependenciesShims.ts`

### New Student Grades
* Frontend:
  1. Non-AP component `ui/features/grade_summary/react/GradeSummary/AssignmentTableRows/AssignmentRow.jsx`, which uses --
  2. AP component `ui/features/grade_summary/react/LtiAssetProcessorCell.tsx`, which uses --
  3. AP components `LtiAssetReportStatus` and `LtiStudentAssetReportModal`

* Data: part of Grades graphql query in
  `ui/features/grade_summary/graphql/Assignment.js` and
  `ui/features/grade_summary/graphql/Submission.js` (note: query shared with
  New Student Submission AP)

### Old Student Grades
* Frontend:
  1. Non-AP, non-React `ui/features/grade_summary/jquery/index.jsx` renders --
  2. AP component `ui/features/grade_summary/react/LtiAssetProcessorCellWithData.tsx` which uses --
  3. AP component `ui/features/grade_summary/react/LtiAssetProcessorCell.tsx`, which uses --
  4. AP components `LtiAssetReportStatus` and `LtiStudentAssetReportModal`

* Data: `ui/features/grade_summary/react/LtiAssetProcessorCellWithData.tsx` uses
  `ui/shared/lti-asset-processor/react/hooks/useCourseAssignmentsAssetReports.ts` which use
  Tanstack Query + GraphQL to get all Asset Processors and Asset Reports for
  the student and course.

### New student Submission
* Frontend 1 -- single attachment or RCE content:
  * `ui/features/assignments_show_student/react/components/StudentContent.jsx` renders --
  * `ui/features/assignments_show_student/react/components/DocumentProcessorsSection.tsx`
    checks `useShouldShowLtiAssetReportsForStudent()` and renders
    `LtiAssetReportsForStudentSubmission` along with some Submission-specific
    presentational components
* Frontend 2 -- multiple attachments
  * `ui/features/assignments_show_student/react/components/AttemptTab.jsx` lazy-loads
  * `ui/features/assignments_show_student/react/components/AttemptType/FilePreview.jsx` checks
    `useShouldShowLtiAssetReportsForStudent()` and renders
    `LtiAssetReportsForStudentSubmission`
* Data
  * `LtiAssetReportsForStudentSubmission` uses hook in
    `useLtiAssetProcessorsAndReportsForStudent` which use Tanstack Query +
    GraphQL to fetch data

### Old Student Submission
* Frontend 1 -- Text Entry or Discussion Entry
  1. View `app/views/submissions/show.html.erb` renders container div `asset_report_status_container`
  2. `ui/features/submissions/jquery/index.jsx` (non-React) renders `TextEntryAssetReportStatusLink` into that container div.

* Frontend 2 -- Attachment
  * Part A -- Modal (on main window)
      1. View `app/views/submissions/show.html.erb` renders container div `asset_report_modal`
      2. `ui/features/submissions/jquery/index.jsx` renders `StudentAssetReportModalWrapper` into that iframe.
      3. `StudentAssetReportModalWrapper` listens to postMessages with reports data to display. (see next part)
  * Part B -- Status Links (inside iframe)
    1. `app/views/submissions/show_preview.html.erb` renders container elements `asset-report-status-header` and `asset-report-status-container`.
    2. `ui/features/submissions_show_preview_asset_report_status/react/index.tsx` renders into those divs (in particular, using the `LtiAssetReportStatus` component). This file also makes the status links send a `postMessage` when clicked, to open up the modal in the main window.
