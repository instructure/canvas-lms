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

export default class GradingPeriodAssignmentsLoader {
  constructor({dispatch, gradebook}) {
    this._dispatch = dispatch
    this._gradebook = gradebook
  }

  loadGradingPeriodAssignments() {
    const courseId = this._gradebook.course.id
    const url = `/courses/${courseId}/gradebook/grading_period_assignments`

    return this._dispatch.getJSON(url).then(data => {
      this._gradebook.updateGradingPeriodAssignments(data.grading_period_assignments)
    })
  }
}
