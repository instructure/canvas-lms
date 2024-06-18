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

import * as GradingSchemeHelper from '../GradingSchemeHelper'

describe('GradingSchemeHelper', () => {
  let gradingScheme

  beforeEach(() => {
    gradingScheme = [
      ['A', 0.9],
      ['B', 0.8],
      ['C', 0.7],
      ['D', 0.6],
      ['F', 0.5],
    ]
  })

  describe('.gradeToScoreUpperBound()', () => {
    test('returns 100 when the grade is the first scheme key', () => {
      expect(GradingSchemeHelper.gradeToScoreUpperBound('A', gradingScheme)).toBe(100)
    })

    test('returns 1% below the next highest scheme value', () => {
      expect(GradingSchemeHelper.gradeToScoreUpperBound('B', gradingScheme)).toBe(89)
    })

    test('returns 0.1% below the next highest scheme value when higher by 1%', () => {
      gradingScheme[1][1] = 0.89
      expect(GradingSchemeHelper.gradeToScoreUpperBound('B', gradingScheme)).toBeCloseTo(89.9)
    })

    test('returns 0.1% below the next highest scheme value when higher by less than 1%', () => {
      gradingScheme[1][1] = 0.895
      expect(GradingSchemeHelper.gradeToScoreUpperBound('B', gradingScheme)).toBeCloseTo(89.9)
    })

    test('returns 0.01% below the next highest scheme value when higher by less than .1%', () => {
      gradingScheme[0][1] = 0.9059
      gradingScheme[1][1] = 0.9051
      expect(GradingSchemeHelper.gradeToScoreUpperBound('B', gradingScheme)).toBeCloseTo(90.58)
    })

    test('rounds the returned score to two decimal places', () => {
      gradingScheme[0][1] = 0.8888888888
      gradingScheme[1][1] = 0.85
      expect(GradingSchemeHelper.gradeToScoreUpperBound('B', gradingScheme)).toBeCloseTo(87.89)
    })

    test('matches the first scheme key without case sensitivity', () => {
      expect(GradingSchemeHelper.gradeToScoreUpperBound('a', gradingScheme)).toBe(100)
    })

    test('matches other scheme keys without case sensitivity', () => {
      expect(GradingSchemeHelper.gradeToScoreUpperBound('c', gradingScheme)).toBe(79)
    })

    test('matches numerical scheme keys', () => {
      gradingScheme = [
        ['4.0', 0.9],
        ['3.5', 0.8],
        ['3.0', 0.7],
        ['2.5', 0.6],
        ['2.0', 0.5],
      ]
      expect(GradingSchemeHelper.gradeToScoreUpperBound('2.5', gradingScheme)).toBe(69)
    })

    test('matches scheme keys with arbitrary text', () => {
      gradingScheme = [
        ['4x', 0.9],
        ['-*', 0.8],
        ['å +', 0.7],
        ['+4', 0.6],
        ['!^', 0.5],
      ]
      expect(GradingSchemeHelper.gradeToScoreUpperBound('å +', gradingScheme)).toBe(79)
    })

    test('matches scheme keys with surrounding whitespace', () => {
      gradingScheme = [
        ['4x', 0.9],
        ['-*', 0.8],
        ['å +', 0.7],
        ['+4', 0.6],
        ['!^', 0.5],
      ]
      expect(GradingSchemeHelper.gradeToScoreUpperBound('   !^   ', gradingScheme)).toBe(59)
    })

    test('matches emoji scheme keys', () => {
      gradingScheme = [
        ['😂', 0.9],
        ['🙂', 0.8],
        ['😐', 0.7],
        ['😢', 0.6],
        ['💩', 0],
      ]
      expect(GradingSchemeHelper.gradeToScoreUpperBound('😐', gradingScheme)).toBe(79)
    })

    test('returns null when the grade does not match a scheme key', () => {
      expect(GradingSchemeHelper.gradeToScoreUpperBound('B+', gradingScheme)).toBeNull()
    })
  })

  describe('.gradeToScoreLowerBound()', () => {
    test('returns the lower bound of a grade', () => {
      expect(GradingSchemeHelper.gradeToScoreLowerBound('B', gradingScheme)).toBe(80)
    })

    test('rounds the returned score to two decimal places', () => {
      gradingScheme[1][1] = 0.8588888
      expect(GradingSchemeHelper.gradeToScoreLowerBound('B', gradingScheme)).toBeCloseTo(85.89)
    })

    test('matches the first scheme key without case sensitivity', () => {
      expect(GradingSchemeHelper.gradeToScoreLowerBound('c', gradingScheme)).toBe(70)
    })

    test('matches numerical scheme keys', () => {
      gradingScheme = [
        ['4.0', 0.9],
        ['3.5', 0.8],
        ['3.0', 0.7],
        ['2.5', 0.6],
        ['2.0', 0.5],
      ]
      expect(GradingSchemeHelper.gradeToScoreLowerBound('2.5', gradingScheme)).toBe(60)
    })

    test('matches scheme keys with arbitrary text', () => {
      gradingScheme = [
        ['4x', 0.9],
        ['-*', 0.8],
        ['å +', 0.7],
        ['+4', 0.6],
        ['!^', 0.5],
      ]
      expect(GradingSchemeHelper.gradeToScoreLowerBound('å +', gradingScheme)).toBe(70)
    })

    test('matches scheme keys with surrounding whitespace', () => {
      gradingScheme = [
        ['4x', 0.9],
        ['-*', 0.8],
        ['å +', 0.7],
        ['+4', 0.6],
        ['!^', 0.5],
      ]
      expect(GradingSchemeHelper.gradeToScoreLowerBound('   !^   ', gradingScheme)).toBe(50)
    })

    test('matches grades with trailing en-dash to keys with trailing en-dash', () => {
      gradingScheme = [
        ['A', 0.95],
        ['A-', 0.9],
        ['B', 0.85],
      ]
      const enDash = '-'
      expect(GradingSchemeHelper.gradeToScoreLowerBound(`A${enDash}`, gradingScheme)).toBe(90)
    })

    test('matches grades with trailing minus to keys with trailing en-dash', () => {
      gradingScheme = [
        ['A', 0.95],
        ['A-', 0.9],
        ['B', 0.85],
      ]
      const minus = '−'
      expect(GradingSchemeHelper.gradeToScoreLowerBound(`A${minus}`, gradingScheme)).toBe(90)
    })

    test('matches emoji scheme keys', () => {
      gradingScheme = [
        ['😂', 0.9],
        ['🙂', 0.8],
        ['😐', 0.7],
        ['😢', 0.6],
        ['💩', 0],
      ]
      expect(GradingSchemeHelper.gradeToScoreLowerBound('😐', gradingScheme)).toBe(70)
    })

    test('returns null when the grade does not match a scheme key', () => {
      expect(GradingSchemeHelper.gradeToScoreLowerBound('B+', gradingScheme)).toBeNull()
    })
  })
})
