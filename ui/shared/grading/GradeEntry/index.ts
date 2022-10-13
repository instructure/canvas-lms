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

export const EnterGradesAs = Object.freeze({
  GRADING_SCHEME: 'gradingScheme',
  PASS_FAIL: 'passFail',
  PERCENTAGE: 'percent',
  POINTS: 'points',
})

export default class GradeEntry {
  constructor(options = {}) {
    this.options = {
      ...options,
    }
  }

  get enterGradesAs() {
    return EnterGradesAs.POINTS
  }

  get gradingScheme() {
    return this.options.gradingScheme || null
  }

  formatGradeInfoForDisplay(/* gradeInfo */) {
    return null
  }

  formatGradeInfoForInput(/* gradeInfo */) {
    return null
  }

  hasGradeChanged(/* assignedGradeInfo, currentGradeInfo, previousGradeInfo */) {
    return false
  }

  parseValue(/* value */) {
    return null
  }
}
