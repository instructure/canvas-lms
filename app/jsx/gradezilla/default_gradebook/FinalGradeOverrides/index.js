/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import FinalGradeOverrideDatastore from './FinalGradeOverrideDatastore'

export default class FinalGradeOverrides {
  constructor(gradebook) {
    this._gradebook = gradebook
    this._datastore = new FinalGradeOverrideDatastore()
  }

  getGradeForUser(userId) {
    let gradingPeriodId = null
    if (this._gradebook.isFilteringColumnsByGradingPeriod()) {
      gradingPeriodId = this._gradebook.getGradingPeriodToShow()
    }

    return this._datastore.getGrade(userId, gradingPeriodId)
  }

  setGrades(gradeOverrides) {
    this._datastore.setGrades(gradeOverrides)
    const studentIds = Object.keys(gradeOverrides)
    studentIds.forEach(userId => {
      this._gradebook.gradebookGrid.updateRowCell(userId, 'total_grade_override')
    })
  }
}
