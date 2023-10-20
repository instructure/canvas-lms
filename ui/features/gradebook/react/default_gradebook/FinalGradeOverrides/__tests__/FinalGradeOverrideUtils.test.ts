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

import {gradeOverrideCustomStatus} from '../FinalGradeOverride.utils'

describe('FinalGradeOverride.utils Tests', () => {
  describe('gradeOverrideCustomStatus', () => {
    const studentId = '1'

    it('returns null if no overrides for student', () => {
      const finalGradeOverrides = {}
      const gradingPeriodId = '1'
      expect(gradeOverrideCustomStatus(finalGradeOverrides, studentId, gradingPeriodId)).toBe(null)
    })

    it('returns course customGradingStatus if no gradingPeriodId provided', () => {
      const finalGradeOverrides = {
        '1': {
          courseGrade: {
            customGradeStatusId: '1',
          },
        },
      }
      const gradingPeriodId = undefined
      expect(gradeOverrideCustomStatus(finalGradeOverrides, studentId, gradingPeriodId)).toBe('1')
    })

    it('returns course customGradeStatusId if gradingPeriodId is 0', () => {
      const finalGradeOverrides = {
        '1': {
          courseGrade: {
            customGradeStatusId: '1',
          },
        },
      }
      const gradingPeriodId = '0'
      expect(gradeOverrideCustomStatus(finalGradeOverrides, studentId, gradingPeriodId)).toBe('1')
    })

    it('returns undefined if course customGradeStatusId does not exist', () => {
      const finalGradeOverrides = {
        '1': {
          courseGrade: {},
        },
      }
      const gradingPeriodId = '0'
      expect(gradeOverrideCustomStatus(finalGradeOverrides, studentId, gradingPeriodId)).toBe(
        undefined
      )
    })

    it('returns customGradeStatusId if gradingPeriodId is not 0', () => {
      const finalGradeOverrides = {
        '1': {
          gradingPeriodGrades: {
            '1': {
              customGradeStatusId: '1',
            },
          },
        },
      }
      const gradingPeriodId = '1'
      expect(gradeOverrideCustomStatus(finalGradeOverrides, studentId, gradingPeriodId)).toBe('1')
    })

    it('returns undefined if grading period in finalGradeOverrides does not exist', () => {
      const finalGradeOverrides = {
        '1': {
          gradingPeriodGrades: {
            '1': {
              customGradeStatusId: '1',
            },
          },
        },
      }
      const gradingPeriodId = '2'
      expect(gradeOverrideCustomStatus(finalGradeOverrides, studentId, gradingPeriodId)).toBe(
        undefined
      )
    })
  })
})
