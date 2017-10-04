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
    colors: {},
    context_allows_gradebook_uploads: true,
    context_id: '1',
    context_url: '/courses/1/',
    currentUserId: '1',
    export_gradebook_csv_url: 'http://example.com/export',
    gradebook_import_url: 'http://example.com/import',
    gradebook_is_editable: true,
    graded_late_or_missing_submissions_exist: false,
    locale: 'en',
    new_gradebook_development_enabled: true,
    outcome_gradebook_enabled: false,
    post_grades_ltis: [],
    sections: [],
    settings: {
      show_concluded_enrollments: 'false',
      show_inactive_enrollments: 'false'
    },
    closed_grading_period_ids: [],
    speed_grader_enabled: true,
    ...options
  });
  gradebook.keyboardNav = {
    addGradebookElement () {},
    removeGradebookElement () {}
  };

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
        <div id="search-filter-container">
          <input type="text" />
        </div>
        <div id="gradebook-settings-modal-button-container"></div>
        <div data-component="GradebookSettingsModal"></div>
        <div data-component="StatusesModal"></div>
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
