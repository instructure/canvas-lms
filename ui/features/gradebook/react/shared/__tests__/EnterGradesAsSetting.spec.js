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

import * as EnterGradesAsSetting from '../EnterGradesAsSetting'

describe('EnterGradesAsSetting', () => {
  describe('.defaultOptionForGradingType', () => {
    test('is "points" for the "points" grading type', () => {
      expect(EnterGradesAsSetting.defaultOptionForGradingType('points')).toBe('points')
    })

    test('is "percent" for the "percent" grading type', () => {
      expect(EnterGradesAsSetting.defaultOptionForGradingType('percent')).toBe('percent')
    })

    test('is "gradingScheme" for the "gpa_scale" grading type', () => {
      expect(EnterGradesAsSetting.defaultOptionForGradingType('gpa_scale')).toBe('gradingScheme')
    })

    test('is "gradingScheme" for the "letter_grade" grading type', () => {
      expect(EnterGradesAsSetting.defaultOptionForGradingType('letter_grade')).toBe('gradingScheme')
    })

    test('is "passFail" for the "pass_fail" grading type', () => {
      expect(EnterGradesAsSetting.defaultOptionForGradingType('pass_fail')).toBe('passFail')
    })

    test('does not exist for the "not_graded" grading type', () => {
      expect(EnterGradesAsSetting.defaultOptionForGradingType('not_graded')).toBeNull()
    })
  })

  describe('.optionsForGradingType', () => {
    test('includes "points" for the "points" grading type', () => {
      expect(EnterGradesAsSetting.optionsForGradingType('points')).toContain('points')
    })

    test('includes "percent" for the "points" grading type', () => {
      expect(EnterGradesAsSetting.optionsForGradingType('points')).toContain('percent')
    })

    test('includes "points" for the "percent" grading type', () => {
      expect(EnterGradesAsSetting.optionsForGradingType('percent')).toContain('points')
    })

    test('includes "percent" for the "percent" grading type', () => {
      expect(EnterGradesAsSetting.optionsForGradingType('percent')).toContain('percent')
    })

    test('includes "points" for the "gpa_scale" grading type', () => {
      expect(EnterGradesAsSetting.optionsForGradingType('gpa_scale')).toContain('points')
    })

    test('includes "percent" for the "gpa_scale" grading type', () => {
      expect(EnterGradesAsSetting.optionsForGradingType('gpa_scale')).toContain('percent')
    })

    test('includes "gradingScheme" for the "gpa_scale" grading type', () => {
      expect(EnterGradesAsSetting.optionsForGradingType('gpa_scale')).toContain('gradingScheme')
    })

    test('includes "points" for the "letter_grade" grading type', () => {
      expect(EnterGradesAsSetting.optionsForGradingType('letter_grade')).toContain('points')
    })

    test('includes "percent" for the "letter_grade" grading type', () => {
      expect(EnterGradesAsSetting.optionsForGradingType('letter_grade')).toContain('percent')
    })

    test('includes "gradingScheme" for the "letter_grade" grading type', () => {
      expect(EnterGradesAsSetting.optionsForGradingType('letter_grade')).toContain('gradingScheme')
    })

    test('includes "passFail" for the "pass_fail" grading type', () => {
      expect(EnterGradesAsSetting.optionsForGradingType('pass_fail')).toContain('passFail')
    })

    test('do not exist for the "not_graded" grading type', () => {
      expect(EnterGradesAsSetting.optionsForGradingType('not_graded')).toEqual([])
    })
  })
})
