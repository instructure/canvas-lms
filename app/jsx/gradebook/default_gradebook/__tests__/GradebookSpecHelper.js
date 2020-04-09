/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import Gradebook from 'compiled/gradebook/Gradebook'

export function createGradebook(options = {}) {
  const gradebook = new Gradebook({
    api_max_per_page: 50,
    assignment_groups_url: '/api/v1/assignment_groups',
    chunk_size: 50,
    closed_grading_period_ids: [],
    colors: {},
    context_allows_gradebook_uploads: true,
    context_id: '1',
    context_modules_url: '/api/v1/courses/1201/context_modules',
    context_url: '/courses/1/',

    course_settings: {
      allow_final_grade_override: false,
      filter_speed_grader_by_student_group: false
    },

    currentUserId: '1',
    custom_column_data_url: '/api/v1/courses/1201/custom_gradebook_columns/:id',
    custom_columns_url: '/api/v1/courses/1201/custom_gradebook_columns',
    dataloader_improvements: true,
    default_grading_standard: [
      ['A', 0.9],
      ['B', 0.8],
      ['C', 0.7],
      ['D', 0.6],
      ['F', 0.0]
    ],
    editable: true,
    export_gradebook_csv_url: 'http://example.com/export',
    final_grade_override_enabled: false,
    gradebook_column_order_settings_url: 'http://example.com/gradebook_column_order_settings_url',
    gradebook_import_url: 'http://example.com/import',
    gradebook_is_editable: true,
    graded_late_submissions_exist: false,
    grading_schemes: [
      {
        id: '2801',
        data: [
          ['😂', 0.9],
          ['🙂', 0.8],
          ['😐', 0.7],
          ['😢', 0.6],
          ['💩', 0]
        ],
        title: 'Emoji Grades'
      }
    ],
    latePolicyStatusDisabled: false,
    locale: 'en',
    new_gradebook_development_enabled: true,
    outcome_gradebook_enabled: false,
    performanceControls: {
      active_request_limit: 10
    },
    post_grades_ltis: [],
    post_policies_enabled: true,
    publish_to_sis_enabled: false,
    sections: [],

    settings: {
      show_concluded_enrollments: 'false',
      show_inactive_enrollments: 'false'
    },

    settings_update_url: '/path/to/settingsUpdateUrl',
    speed_grader_enabled: true,
    student_groups: [],
    // TODO: remove `students_stateless_url` with TALLY-831
    students_stateless_url: '/api/v1/courses/1201/users',
    // TODO: remove `submissions_url` with TALLY-831
    submissions_url: '/api/v1/courses/1201/students/submissions',
    ...options
  })

  gradebook.keyboardNav = {
    addGradebookElement() {},
    removeGradebookElement() {}
  }

  gradebook.gradebookGrid.gridSupport = {
    columns: {
      updateColumnHeaders() {},
      scrollToStart() {},
      scrollToEnd() {}
    }
  }

  return gradebook
}

export function setFixtureHtml($fixture) {
  return ($fixture.innerHTML = `
    <div id="application">
      <div id="wrapper">
        <div data-component="GridColor"></div>
        <span data-component="GradebookMenu" data-variant="DefaultGradebook"></span>
        <span data-component="ViewOptionsMenu"></span>
        <span data-component="ActionMenu"></span>
        <div id="assignment-group-filter-container"></div>
        <div id="grading-periods-filter-container"></div>
        <div id="modules-filter-container"></div>
        <div id="sections-filter-container"></div>
        <div id="student-group-filter-container"></div>
        <div id="search-filter-container">
          <input type="text" />
        </div>
        <div id="gradebook-settings-modal-button-container"></div>
        <div data-component="GradebookSettingsModal"></div>
        <div id="hide-assignment-grades-tray"></div>
        <div id="post-assignment-grades-tray"></div>
        <div id="assignment-posting-policy-tray"></div>
        <div data-component="StatusesModal"></div>
        <div data-component="AnonymousSpeedGraderAlert"></div>
        <div id="StudentTray__Container"></div>
        <div id="gradebook_grid"></div>
      </div>
    </div>
  `)
}
