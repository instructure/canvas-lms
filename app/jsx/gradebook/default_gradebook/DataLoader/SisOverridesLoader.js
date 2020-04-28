/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

export default class SisOverridesLoader {
  constructor({dispatch, gradebook}) {
    this._dispatch = dispatch
    this._gradebook = gradebook
  }

  loadOverrides() {
    const courseId = this._gradebook.course.id
    const url = `/api/v1/courses/${courseId}/assignment_groups`

    const params = {
      exclude_assignment_submission_types: ['wiki_page'],
      exclude_response_fields: ['description', 'in_closed_grading_period', 'needs_grading_count'],
      include: ['assignments', 'grades_published', 'overrides'],
      override_assignment_dates: false
    }

    this._dispatch.getDepaginated(url, params).then(data => {
      this._gradebook.addOverridesToPostGradesStore(data)
    })
  }
}
