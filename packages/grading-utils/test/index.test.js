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

// eslint-disable-next-line import/no-extraneous-dependencies
import {describe, test, expect} from '@jest/globals'
import {scoreToGrade} from '../lib/index'

describe('index', () => {
  describe('scoreToGrade', () => {
    test('returns null when scheme is null or score is NaN', () => {
      const gradingScheme = [
        ['A', 0.9],
        ['B', 0.8],
        ['C', 0.7],
        ['D', 0.6],
        ['E', 0.5],
      ]

      expect(scoreToGrade(Number.NaN, gradingScheme)).toBe(null)
      expect(scoreToGrade(40, null)).toBe(null)
      expect(scoreToGrade('40', gradingScheme)).toBe(null)
      expect(scoreToGrade('B', gradingScheme)).toBe(null)
    })

    test('returns the lowest grade to below-scale scores', () => {
      const gradingScheme = [
        ['A', 0.9],
        ['B', 0.8],
        ['C', 0.7],
        ['D', 0.6],
        ['E', 0.5],
      ]

      expect(scoreToGrade(40, gradingScheme)).toBe('E')
    })

    test('accounts for floating-point rounding errors', () => {
      const gradingScheme = [
        ['A', 0.9],
        ['B+', 0.886],
        ['B', 0.8],
        ['C', 0.695],
        ['D', 0.555],
        ['E', 0.545],
        ['M', 0.0],
      ]

      expect(scoreToGrade(1005, gradingScheme)).toBe('A')
      expect(scoreToGrade(105, gradingScheme)).toBe('A')
      expect(scoreToGrade(100, gradingScheme)).toBe('A')
      expect(scoreToGrade(99, gradingScheme)).toBe('A')
      expect(scoreToGrade(90, gradingScheme)).toBe('A')
      expect(scoreToGrade(89.999, gradingScheme)).toBe('B+')
      expect(scoreToGrade(88.601, gradingScheme)).toBe('B+')
      expect(scoreToGrade(88.6, gradingScheme)).toBe('B+')
      expect(scoreToGrade(88.599, gradingScheme)).toBe('B')
      expect(scoreToGrade(80, gradingScheme)).toBe('B')
      expect(scoreToGrade(79.999, gradingScheme)).toBe('C')
      expect(scoreToGrade(79, gradingScheme)).toBe('C')
      expect(scoreToGrade(69.501, gradingScheme)).toBe('C')
      expect(scoreToGrade(69.5, gradingScheme)).toBe('C')
      expect(scoreToGrade(69.499, gradingScheme)).toBe('D')
      expect(scoreToGrade(60, gradingScheme)).toBe('D')
      expect(scoreToGrade(55.5, gradingScheme)).toBe('D')
      expect(scoreToGrade(54.5, gradingScheme)).toBe('E')
      expect(scoreToGrade(50, gradingScheme)).toBe('M')
      expect(scoreToGrade(0, gradingScheme)).toBe('M')
      expect(scoreToGrade(-100, gradingScheme)).toBe('M')
    })
  })
})
