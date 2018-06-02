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

import Gradebook from 'compiled/gradezilla/Gradebook';

export function createGradebook (options = {}) {
  const gradebook = new Gradebook({
    anonymous_moderated_marking_enabled: false,
    colors: {},
    context_allows_gradebook_uploads: true,
    context_id: '1',
    context_url: '/courses/1/',
    currentUserId: '1',
    default_grading_standard: [['A', 0.90], ['B', 0.80], ['C', 0.70], ['D', 0.60], ['F', 0.0]],
    editable: true,
    export_gradebook_csv_url: 'http://example.com/export',
    gradebook_column_order_settings_url: 'http://example.com/gradebook_column_order_settings_url',
    gradebook_import_url: 'http://example.com/import',
    gradebook_is_editable: true,
    graded_late_submissions_exist: false,
    grading_schemes: [
      { id: '2801', data: [['😂', 0.9], ['🙂', 0.8], ['😐', 0.7], ['😢', 0.6], ['💩', 0]], title: 'Emoji Grades' }
    ],
    locale: 'en',
    latePolicyStatusDisabled: false,
    new_gradebook_development_enabled: true,
    outcome_gradebook_enabled: false,
    post_grades_ltis: [],
    publish_to_sis_enabled: false,
    sections: [],
    settings: {
      show_concluded_enrollments: 'false',
      show_inactive_enrollments: 'false'
    },
    settings_update_url: '/path/to/settingsUpdateUrl',
    closed_grading_period_ids: [],
    speed_grader_enabled: true,
    ...options
  });
  gradebook.keyboardNav = {
    addGradebookElement () {},
    removeGradebookElement () {}
  };
  gradebook.gradebookGrid.gridSupport = {
    columns: {
      updateColumnHeaders () {},
      scrollToStart () {},
      scrollToEnd () {}
    }
  }

  return gradebook;
}

export function setFixtureHtml ($fixture) {
  /* eslint-disable no-param-reassign */
  $fixture.innerHTML = `
    <div id="application">
      <div id="wrapper">
        <div data-component="GridColor"></div>
        <div data-component="ViewOptionsMenu"></div>
        <div data-component="ActionMenu"></div>
        <div id="assignment-group-filter-container"></div>
        <div id="grading-periods-filter-container"></div>
        <div id="modules-filter-container"></div>
        <div id="sections-filter-container"></div>
        <div id="search-filter-container">
          <input type="text" />
        </div>
        <div id="gradebook-settings-modal-button-container"></div>
        <div data-component="GradebookSettingsModal"></div>
        <div data-component="StatusesModal"></div>
        <div data-component="AnonymousSpeedGraderAlert"></div>
        <div id="StudentTray__Container"></div>
        <div id="gradebook_grid"></div>
      </div>
    </div>
  `;
  /* eslint-enable no-param-reassign */
}

export default {
  createGradebook
};
