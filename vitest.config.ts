/// <reference types="vitest" />

/*
 * Copyright (C) 2023 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import {defineConfig} from 'vitest/config'
import handlebarsPlugin from './ui-build/esbuild/handlebars-plugin'
import svgPlugin from './ui-build/esbuild/svg-plugin'

export default defineConfig({
  test: {
    environment: 'happy-dom',
    globals: true,
    setupFiles: 'ui/setup-vitests.tsx',
    include: ['ui/**/__tests__/**/*.test.?(c|m)[jt]s?(x)', 'packages/**/__tests__/**/*.test.?(c|m)[jt]s?(x)'],
    exclude: [
      'ui/boot/initializers/**/*',
      'ui/features/account_calendar_settings/**/*',
      'ui/features/account_course_user_search/**/*',
      'ui/features/account_grading_settings/**/*',
      'ui/features/account_notification_settings/**/*',
      'ui/features/account_settings/**/*',
      'ui/features/assignment_edit/**/*',
      'ui/features/assignment_grade_summary/**/*',
      'ui/features/assignment_index/**/*',
      'ui/features/assignments_show_student/**/*',
      'ui/features/assignments_show_teacher/**/*',
      'ui/features/brand_configs/**/*',
      'ui/features/calendar/**/*',
      'ui/features/conferences/**/*',
      'ui/features/content_migrations/**/*',
      'ui/features/content_shares/**/*',
      'ui/features/course_paces/**/*',
      'ui/features/course_people/**/*',
      'ui/features/course_settings/**/*',
      'ui/features/dashboard/**/*',
      'ui/features/developer_keys_v2/**/*',
      'ui/features/discussion_topic_edit_v2/**/*',
      'ui/features/discussion_topics_post/**/*',
      'ui/features/discussion_topics/**/*',
      'ui/features/edit_calendar_event/**/*',
      'ui/features/enhanced_individual_gradebook/**/*',
      'ui/features/external_apps/**/*',
      'ui/features/files/**/*',
      'ui/features/grade_summary/**/*',
      'ui/features/gradebook_history/**/*',
      'ui/features/gradebook/**/*',
      'ui/features/inbox/**/*',
      'ui/features/job_stats/**/*',
      'ui/features/jobs_v2/**/*',
      'ui/features/k5_course/**/*',
      'ui/features/k5_dashboard/**/*',
      'ui/features/learning_mastery_v2/**/*',
      'ui/features/navigation_header/**/*',
      'ui/features/outcome_management/**/*',
      'ui/features/permissions/**/*',
      'ui/features/post_message_forwarding/**/*',
      'ui/features/quiz_log_auditing/**/*',
      'ui/features/quiz_statistics/**/*',
      'ui/features/quizzes_index/**/*',
      'ui/features/rubrics/**/*',
      'ui/features/speed_grader/**/*',
      'ui/features/submit_assignment/**/*',
      'ui/features/syllabus/**/*',
      'ui/shared/apollo-v3/**/*',
      'ui/shared/apollo/**/*',
      'ui/shared/assignments/**/*',
      'ui/shared/brandable-css/**/*',
      'ui/shared/calendar-conferences/**/*',
      'ui/shared/calendar/**/*',
      'ui/shared/canvas-media-player/**/*',
      'ui/shared/context-module-file-drop/**/*',
      'ui/shared/context-modules/**/*',
      'ui/shared/copy-to-clipboard/**/*',
      'ui/shared/dashboard-card/**/*',
      'ui/shared/datetime/**/*',
      'ui/shared/deep-linking/**/*',
      'ui/shared/direct-sharing/**/*',
      'ui/shared/discussions/**/*',
      'ui/shared/error-boundary/**/*',
      'ui/shared/external-tools/**/*',
      'ui/shared/feature-flags/**/*',
      'ui/shared/files/**/*',
      'ui/shared/final-grade-override/**/*',
      'ui/shared/generic-error-page/**/*',
      'ui/shared/grade-summary/**/*',
      'ui/shared/grading_scheme/**/*',
      'ui/shared/grading/**/*',
      'ui/shared/graphql-query-mock/**/*',
      'ui/shared/group-modal/**/*',
      'ui/shared/immersive-reader/**/*', // fails inline snapshot
      'ui/shared/integrations/**/*',
      'ui/shared/k5/**/*',
      'ui/shared/mediaelement/**/*',
      'ui/shared/message-attachments/**/*',
      'ui/shared/message-students-dialog/**/*',
      'ui/shared/message-students-modal/**/*',
      'ui/shared/network/**/*',
      'ui/shared/notification-preferences-course/**/*',
      'ui/shared/outcomes/**/*',
      'ui/shared/planner/**/*',
      'ui/shared/publish-button-view/**/*',
      'ui/shared/rce/**/*',
      'ui/shared/rubrics/**/*',
      'ui/shared/search-item-selector/**/*',
      'ui/shared/submission-sticker/**/*',
      'ui/shared/temporary-enrollment/**/*',
      'ui/shared/tinymce-external-tools/**/*',
      'ui/shared/use-state-with-callback-hook/**/*',
      'ui/shared/wiki/**/*',
      'ui/shared/with-breakpoints/**/*',
    ],
    coverage: {
      include: ['ui/**/*.ts?(x)', 'ui/**/*.js?(x)'],
      exclude: ['ui/**/__tests__/**/*'],
      reportOnFailure: true,
    },
  },
  plugins: [handlebarsPlugin(), svgPlugin()],
})
