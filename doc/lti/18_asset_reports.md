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
* Full data flow:
  1. Controller `app/controllers/gradebooks_controller.rb` sets `js_env` `submissions`
  2. Non-AP, non-React `ui/features/grade_summary/jquery/index.jsx` uses ENV and renders --
  3. AP component `ui/features/grade_summary/react/LtiAssetProcessorCell.tsx` which uses --
  4. AP components `LtiAssetReportStatus` and `LtiStudentAssetReportModal`

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
* Full data flow 1 (text entry)
  1. Controller `app/controllers/submissions_base_controller.rb` sets `@asset_reports`
  2. View `app/views/submissions/show.html.erb` sets `js_env ... ASSET_REPORTS` (`online_text_entry` only)
  3. UI `ui/features/submissions/jquery/index.jsx` (non-React) gets from ENV, and (if mount point `asset_report_text_entry_status_container` rendered by view exists) renders
  4. AP React Component `ui/features/submissions/react/TextEntryAssetReportStatusLink.tsx` 
  5. That uses `StudentAssetReportModal` and `AssetReportStatus`
* POST-REFACTOR: something simple will probably work, similar to new speedgrader single attachment/RCE

* Full data flow 2 (attachment)
  1. Controller `app/controllers/submissions/previews_base_controller.rb` sets `@asset_processors`
  2. View `app/views/submissions/show_preview.html.erb` sets `js_env ... ASSET_REPORTS` and includes with `js_bundle`
  3. feature `ui/features/submissions_show_preview_asset_report_status/` which reads from ENV and renders
  4. AP React Component `OnlineUploadAssetReportStatusLink`
  5. After clicking status link, data is passed via `ASSET_REPORT_MODAL_EVENT` postMessage to `StudentAssetReportModalWrapper` (rendered in `ui/features/submissions/jquery/index.jsx`)
* POST-REFACTOR: need to render each attachment individual status (into non-React) and have send *postMessage* with particular attachment ID. postMessage has the data actually.
change StudentAssetReportModal to be like ui/shared/lti-asset-processor/react/LtiAssetReportsForStudentSubmission.tsx but implement its own openModal -- doing the postMessage stuff

* Note that `features/submissions_show_preview_asset_report_status` and
  StudentAssetReportModalWrapper are in different iframes and use postMessage

* Original implementation:
  b57c8eba3abb32ea76db2fc105d3ddda44335544
  and
  bc16ceb8ca005f59e57b5f905618ad03e3f3df3a (text entry, both old + new pages)

