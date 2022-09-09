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

import * as EnterGradesAsSetting from 'ui/features/gradebook/react/shared/EnterGradesAsSetting'

QUnit.module('EnterGradesAsSetting', () => {
  QUnit.module('.defaultOptionForGradingType', () => {
    test('is "points" for the "points" grading type', () => {
      equal(EnterGradesAsSetting.defaultOptionForGradingType('points'), 'points')
    })

    test('is "percent" for the "percent" grading type', () => {
      equal(EnterGradesAsSetting.defaultOptionForGradingType('percent'), 'percent')
    })

    test('is "gradingScheme" for the "gpa_scale" grading type', () => {
      equal(EnterGradesAsSetting.defaultOptionForGradingType('gpa_scale'), 'gradingScheme')
    })

    test('is "gradingScheme" for the "letter_grade" grading type', () => {
      equal(EnterGradesAsSetting.defaultOptionForGradingType('letter_grade'), 'gradingScheme')
    })

    test('is "passFail" for the "pass_fail" grading type', () => {
      equal(EnterGradesAsSetting.defaultOptionForGradingType('pass_fail'), 'passFail')
    })

    test('does not exist for the "not_graded" grading type', () => {
      strictEqual(EnterGradesAsSetting.defaultOptionForGradingType('not_graded'), null)
    })
  })

  QUnit.module('.optionsForGradingType', () => {
    test('includes "points" for the "points" grading type', () => {
      ok(EnterGradesAsSetting.optionsForGradingType('points').includes('points'))
    })

    test('includes "percent" for the "points" grading type', () => {
      ok(EnterGradesAsSetting.optionsForGradingType('points').includes('percent'))
    })

    test('includes "points" for the "percent" grading type', () => {
      ok(EnterGradesAsSetting.optionsForGradingType('percent').includes('points'))
    })

    test('includes "percent" for the "percent" grading type', () => {
      ok(EnterGradesAsSetting.optionsForGradingType('percent').includes('percent'))
    })

    test('includes "points" for the "gpa_scale" grading type', () => {
      ok(EnterGradesAsSetting.optionsForGradingType('gpa_scale').includes('points'))
    })

    test('includes "percent" for the "gpa_scale" grading type', () => {
      ok(EnterGradesAsSetting.optionsForGradingType('gpa_scale').includes('percent'))
    })

    test('includes "gradingScheme" for the "gpa_scale" grading type', () => {
      ok(EnterGradesAsSetting.optionsForGradingType('gpa_scale').includes('gradingScheme'))
    })

    test('includes "points" for the "letter_grade" grading type', () => {
      ok(EnterGradesAsSetting.optionsForGradingType('letter_grade').includes('points'))
    })

    test('includes "percent" for the "letter_grade" grading type', () => {
      ok(EnterGradesAsSetting.optionsForGradingType('letter_grade').includes('percent'))
    })

    test('includes "gradingScheme" for the "letter_grade" grading type', () => {
      ok(EnterGradesAsSetting.optionsForGradingType('letter_grade').includes('gradingScheme'))
    })

    test('includes "passFail" for the "pass_fail" grading type', () => {
      ok(EnterGradesAsSetting.optionsForGradingType('pass_fail').includes('passFail'))
    })

    test('do not exist for the "not_graded" grading type', () => {
      deepEqual(EnterGradesAsSetting.optionsForGradingType('not_graded'), [])
    })
  })
})
