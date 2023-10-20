// @ts-nocheck
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

import type GradeOverrideInfo from './GradeOverrideInfo'
import type {GradeEntryMode, GradeEntryOptions} from '../grading.d'

export const EnterGradesAs = {
  GRADING_SCHEME: 'gradingScheme',
  PASS_FAIL: 'passFail',
  PERCENTAGE: 'percent',
  POINTS: 'points',
} as const

export default class GradeEntry {
  options: GradeEntryOptions

  constructor(options: GradeEntryOptions) {
    this.options = {
      ...(options || {}),
    }
  }

  get enterGradesAs(): GradeEntryMode {
    return EnterGradesAs.POINTS
  }

  get gradingScheme() {
    return this.options.gradingScheme || null
  }

  formatGradeInfoForDisplay(_gradeInfo) {
    return null
  }

  formatGradeInfoForInput(_gradeInfo) {
    return null
  }

  hasGradeChanged(_assignedGradeInfo, _currentGradeInfo, _previousGradeInfo) {
    return false
  }

  parseValue(_value): GradeOverrideInfo | null {
    return null
  }
}
