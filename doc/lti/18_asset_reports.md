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
  2. AP component `ui/features/grade_summary/react/AssetProcessorCell.tsx`, which uses --
  3. AP components `AssetReportStatus` and `StudentAssetReportModal`

* Data: part of Grades graphql query in
  `ui/features/grade_summary/graphql/Assignment.js` and
  `ui/features/grade_summary/graphql/Submission.js` (note: query shared with
  New Student Submission AP)

### Old Student Grades
* Full data flow:
  1. Controller `app/controllers/gradebooks_controller.rb` sets `js_env` `submissions`
  2. Non-AP, non-React `ui/features/grade_summary/jquery/index.jsx` uses ENV and renders --
  3. AP component `ui/features/grade_summary/react/AssetProcessorCell.tsx` which uses --
  4. AP components `AssetReportStatus` and `StudentAssetReportModal`

### New Student Submission
* Full data flow 1 (multiple attachments):
  1. Contoller `app/controllers/assignments_controller.rb` sets ENV `ASSET_PROCESSORS`
  2. Non-AP component `ui/features/assignments_show_student/react/components/AttemptType/FilePreview.jsx`, which uses ENV and uses --
  3. AP components `AssetReportStatus` and `StudentAssetReportModal`

* Full data flow 2(single attachment or RCE content):
  1. Controller `app/controllers/assignments_controller.rb` sets ENV (same as Full data flow 1), used directly by --
  2. Non-AP component `ui/features/assignments_show_student/react/components/DocumentProcessorsSection.tsx` uses
  3. AP components `AssetReportStatus` and `StudentAssetReportModal`

* Data for both: via ENV (e.g. `ASSET_PROCESSORS`) via `app/controllers/assignments_controller.rb`

* Original implementation:
  35474747d6cf8a4e497071882dbf0245ce79a728
  and
  bc16ceb8ca005f59e57b5f905618ad03e3f3df3a (text entry, both old + new pages)


### Old Student Submission
* Full data flow 1:
  1. Controller `app/controllers/submissions_base_controller.rb` sets `@asset_reports`
  2. View `app/views/submissions/show.html.erb` sets `js_env ... ASSET_REPORTS` (`online_text_entry` only)
  3. UI `ui/features/submissions/jquery/index.jsx` (non-React) gets from ENV, renders
  4. AP React Component `ui/features/submissions/react/TextEntryAssetReportStatusLink.tsx` and
     AP React Component `ui/features/submissions/react/StudentAssetReportModalWrapper.tsx`
  5. Those use `StudentAssetReportModal` and `AssetReportStatus` (both components use `StudentAssetReportModal`?! duplicate?)

* Full data flow 2:
  1. Controller `app/controllers/submissions/previews_base_controller.rb` sets `@asset_processors`
  2. View `app/views/submissions/show_preview.html.erb` sets `js_env ... ASSET_REPORTS` and includes with `js_bundle`
  3. feature `ui/features/submissions_show_preview_asset_report_status/` which reads from ENV and renders
  4. AP React Component `OnlineUploadAssetReportStatusLink`

* Note that `features/submissions_show_preview_asset_report_status` and
  StudentAssetReportModalWrapper are in different iframes and use postMessage

* Original implementation:
  b57c8eba3abb32ea76db2fc105d3ddda44335544
  and
  bc16ceb8ca005f59e57b5f905618ad03e3f3df3a (text entry, both old + new pages)

