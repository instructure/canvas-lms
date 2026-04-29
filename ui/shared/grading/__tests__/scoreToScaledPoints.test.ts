/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {scoreToScaledPoints} from '../GradeCalculationHelper'

describe('scoreToScaledPoints', () => {
  test.each([
    {score: 50, possible: 100, factor: 4.0, expected: 2.0, description: 'half score'},
    {score: 100, possible: 100, factor: 4.0, expected: 4.0, description: 'full score'},
    {score: 0, possible: 100, factor: 4.0, expected: 0.0, description: 'zero score'},
    {score: 87.5, possible: 100, factor: 4.0, expected: 3.5, description: 'partial score'},
    {score: 946.65, possible: 1000, factor: 4.0, expected: 3.7866, description: 'floating point'},
    {score: 75, possible: 100, factor: 5.0, expected: 3.75, description: '5.0 scale'},
    {score: 45, possible: 50, factor: 4.0, expected: 3.6, description: 'non-standard points'},
  ])(
    'converts $description ($score/$possible with $factor scale = $expected)',
    ({score, possible, factor, expected}) => {
      expect(scoreToScaledPoints(score, possible, factor)).toBeCloseTo(expected)
    },
  )

  describe('when score is null', () => {
    test.each([
      {possible: 100, factor: 4.0, description: 'standard 4.0 scale'},
      {possible: 100, factor: 5.0, description: '5.0 scale'},
      {possible: 50, factor: 4.0, description: 'non-standard points'},
      {possible: 200, factor: 10.0, description: '10.0 scale'},
    ])('treats null as 0 with $description', ({possible, factor}) => {
      expect(scoreToScaledPoints(null, possible, factor)).toBeCloseTo(0.0)
    })
  })

  describe('when points possible is 0', () => {
    test.each([
      {score: 5, expected: Infinity, matcher: 'toBe', description: 'positive score'},
      {score: -5, expected: -Infinity, matcher: 'toBe', description: 'negative score'},
      {score: 0, expected: NaN, matcher: 'toBeNaN', description: 'zero score'},
      {score: null, expected: NaN, matcher: 'toBeNaN', description: 'null score'},
    ])('returns $expected for $description', ({score, expected, matcher}) => {
      const result = scoreToScaledPoints(score, 0, 4.0)
      if (matcher === 'toBeNaN') {
        expect(result).toBeNaN()
      } else {
        expect(result).toBe(expected)
      }
    })
  })

  describe('when scaling factor is 0', () => {
    test.each([
      {score: 50, description: 'positive score'},
      {score: 0, description: 'zero score'},
      {score: null, description: 'null score'},
    ])('throws division by zero error for $description', ({score}) => {
      expect(() => scoreToScaledPoints(score, 100, 0)).toThrow('[big.js] Division by zero')
    })
  })

  test.each([
    {score: -10, possible: 100, factor: 4.0, expected: -0.4, description: 'negative score'},
    {score: 110, possible: 100, factor: 4.0, expected: 4.4, description: 'extra credit'},
    {score: 150, possible: 100, factor: 4.0, expected: 6.0, description: 'large extra credit'},
  ])(
    'handles $description ($score/$possible = $expected)',
    ({score, possible, factor, expected}) => {
      expect(scoreToScaledPoints(score, possible, factor)).toBeCloseTo(expected)
    },
  )

  describe('different grading scales', () => {
    test.each([
      {score: 90, possible: 100, factor: 5.0, expected: 4.5, description: '5.0 GPA scale'},
      {score: 80, possible: 100, factor: 10.0, expected: 8.0, description: '10.0 scale'},
      {score: 50, possible: 100, factor: 2.5, expected: 1.25, description: 'fractional factor'},
      {score: 50, possible: 100, factor: 0.5, expected: 0.25, description: 'small factor'},
      {score: 75, possible: 100, factor: 1.0, expected: 0.75, description: '1.0 factor'},
    ])(
      '$description: $score/$possible with $factor = $expected',
      ({score, possible, factor, expected}) => {
        expect(scoreToScaledPoints(score, possible, factor)).toBeCloseTo(expected)
      },
    )
  })

  describe('precision and rounding', () => {
    test.each([
      {
        score: 33.333333,
        possible: 100,
        factor: 4.0,
        expected: 1.3333332,
        precision: 5,
        description: 'repeating decimals',
      },
      {
        score: 0.01,
        possible: 100,
        factor: 4.0,
        expected: 0.0004,
        precision: undefined,
        description: 'very small scores',
      },
      {
        score: 5000,
        possible: 10000,
        factor: 4.0,
        expected: 2.0,
        precision: undefined,
        description: 'large point values',
      },
    ])('handles $description', ({score, possible, factor, expected, precision}) => {
      expect(scoreToScaledPoints(score, possible, factor)).toBeCloseTo(expected, precision)
    })
  })
})
