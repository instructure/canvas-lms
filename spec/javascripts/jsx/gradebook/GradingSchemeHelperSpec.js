/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import * as GradingSchemeHelper from '@canvas/grading/GradingSchemeHelper'

QUnit.module('GradingSchemeHelper', () => {
  QUnit.module('.gradeToScoreUpperBound()', hooks => {
    let gradingScheme

    hooks.beforeEach(() => {
      gradingScheme = [
        ['A', 0.9],
        ['B', 0.8],
        ['C', 0.7],
        ['D', 0.6],
        ['F', 0.5],
      ]
    })

    test('returns 100 when the grade is the first scheme key', () => {
      strictEqual(GradingSchemeHelper.gradeToScoreUpperBound('A', gradingScheme), 100)
    })

    test('returns 1% below the next highest scheme value', () => {
      strictEqual(GradingSchemeHelper.gradeToScoreUpperBound('B', gradingScheme), 89)
    })

    test('returns 0.1% below the next highest scheme value when higher by 1%', () => {
      gradingScheme[1][1] = 0.89
      strictEqual(GradingSchemeHelper.gradeToScoreUpperBound('B', gradingScheme), 89.9)
    })

    test('returns 0.1% below the next highest scheme value when higher by less than 1%', () => {
      gradingScheme[1][1] = 0.895
      strictEqual(GradingSchemeHelper.gradeToScoreUpperBound('B', gradingScheme), 89.9)
    })

    test('returns 0.01% below the next highest scheme value when higher by less than .1%', function () {
      gradingScheme[0][1] = 0.9059
      gradingScheme[1][1] = 0.9051
      strictEqual(GradingSchemeHelper.gradeToScoreUpperBound('B', gradingScheme), 90.58)
    })

    test('rounds the returned score to two decimal places', () => {
      // grading scheme values support only two places of precision on percentages
      gradingScheme[0][1] = 0.8888888888
      gradingScheme[1][1] = 0.85
      strictEqual(GradingSchemeHelper.gradeToScoreUpperBound('B', gradingScheme), 87.89)
    })

    test('matches the first scheme key without case sensitivity', () => {
      strictEqual(GradingSchemeHelper.gradeToScoreUpperBound('a', gradingScheme), 100)
    })

    test('matches other scheme keys without case sensitivity', () => {
      strictEqual(GradingSchemeHelper.gradeToScoreUpperBound('c', gradingScheme), 79)
    })

    test('matches numerical scheme keys', () => {
      gradingScheme = [
        ['4.0', 0.9],
        ['3.5', 0.8],
        ['3.0', 0.7],
        ['2.5', 0.6],
        ['2.0', 0.5],
      ]
      strictEqual(GradingSchemeHelper.gradeToScoreUpperBound('2.5', gradingScheme), 69)
    })

    test('matches scheme keys with arbitrary text', () => {
      gradingScheme = [
        ['4x', 0.9],
        ['-*', 0.8],
        ['å +', 0.7],
        ['+4', 0.6],
        ['!^', 0.5],
      ]
      strictEqual(GradingSchemeHelper.gradeToScoreUpperBound('å +', gradingScheme), 79)
    })

    test('matches scheme keys with surrounding whitespace', () => {
      gradingScheme = [
        ['4x', 0.9],
        ['-*', 0.8],
        ['å +', 0.7],
        ['+4', 0.6],
        ['!^', 0.5],
      ]
      strictEqual(GradingSchemeHelper.gradeToScoreUpperBound('   !^   ', gradingScheme), 59)
    })

    test('matches emoji scheme keys', () => {
      gradingScheme = [
        ['😂', 0.9],
        ['🙂', 0.8],
        ['😐', 0.7],
        ['😢', 0.6],
        ['💩', 0],
      ]
      strictEqual(GradingSchemeHelper.gradeToScoreUpperBound('😐', gradingScheme), 79)
    })

    test('returns null when the grade does not match a scheme key', () => {
      strictEqual(GradingSchemeHelper.gradeToScoreUpperBound('B+', gradingScheme), null)
    })
  })

  QUnit.module('.gradeToScoreLowerBound()', hooks => {
    let gradingScheme

    hooks.beforeEach(() => {
      gradingScheme = [
        ['A', 0.9],
        ['B', 0.8],
        ['C', 0.7],
        ['D', 0.6],
        ['F', 0.5],
      ]
    })

    test('returns the lower bound of a grade', () => {
      strictEqual(GradingSchemeHelper.gradeToScoreLowerBound('B', gradingScheme), 80)
    })

    test('rounds the returned score to two decimal places', () => {
      // grading scheme values support only two places of precision on percentages
      gradingScheme[1][1] = 0.8588888
      strictEqual(GradingSchemeHelper.gradeToScoreLowerBound('B', gradingScheme), 85.89)
    })

    test('matches the first scheme key without case sensitivity', () => {
      strictEqual(GradingSchemeHelper.gradeToScoreLowerBound('c', gradingScheme), 70)
    })

    test('matches numerical scheme keys', () => {
      gradingScheme = [
        ['4.0', 0.9],
        ['3.5', 0.8],
        ['3.0', 0.7],
        ['2.5', 0.6],
        ['2.0', 0.5],
      ]
      strictEqual(GradingSchemeHelper.gradeToScoreLowerBound('2.5', gradingScheme), 60)
    })

    test('matches scheme keys with arbitrary text', () => {
      gradingScheme = [
        ['4x', 0.9],
        ['-*', 0.8],
        ['å +', 0.7],
        ['+4', 0.6],
        ['!^', 0.5],
      ]
      strictEqual(GradingSchemeHelper.gradeToScoreLowerBound('å +', gradingScheme), 70)
    })

    test('matches scheme keys with surrounding whitespace', () => {
      gradingScheme = [
        ['4x', 0.9],
        ['-*', 0.8],
        ['å +', 0.7],
        ['+4', 0.6],
        ['!^', 0.5],
      ]
      strictEqual(GradingSchemeHelper.gradeToScoreLowerBound('   !^   ', gradingScheme), 50)
    })

    test('matches grades with trailing en-dash to keys with trailing en-dash', () => {
      gradingScheme = [
        ['A', 0.95],
        ['A-', 0.9],
        ['B', 0.85],
      ]
      const enDash = '-'
      strictEqual(GradingSchemeHelper.gradeToScoreLowerBound(`A${enDash}`, gradingScheme), 90)
    })

    test('matches grades with trailing minus to keys with trailing en-dash', () => {
      gradingScheme = [
        ['A', 0.95],
        ['A-', 0.9],
        ['B', 0.85],
      ]
      const minus = '−'
      strictEqual(GradingSchemeHelper.gradeToScoreLowerBound(`A${minus}`, gradingScheme), 90)
    })

    test('matches emoji scheme keys', () => {
      gradingScheme = [
        ['😂', 0.9],
        ['🙂', 0.8],
        ['😐', 0.7],
        ['😢', 0.6],
        ['💩', 0],
      ]
      strictEqual(GradingSchemeHelper.gradeToScoreLowerBound('😐', gradingScheme), 70)
    })

    test('returns null when the grade does not match a scheme key', () => {
      strictEqual(GradingSchemeHelper.gradeToScoreLowerBound('B+', gradingScheme), null)
    })
  })
})
