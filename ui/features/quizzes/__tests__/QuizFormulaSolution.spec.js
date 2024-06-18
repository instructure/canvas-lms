/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import QuizFormulaSolution from '../quiz_formula_solution'

describe('QuizFormulaSolution', () => {
  test('sets .result to the given formula', () => {
    const solution = new QuizFormulaSolution('= 0')
    expect(solution.result).toBe('= 0')
  })

  describe('#rawText()', () => {
    const checkText = (input, expected) => {
      const solution = new QuizFormulaSolution(input)
      expect(solution.rawText()).toBe(expected)
    }

    test('returns the right-hand side of the formula', () => {
      checkText('= 0', '0')
      checkText('= 2.5', '2.5')
      checkText('= 17', '17')
      checkText('= -25.12', '-25.12')
      checkText('= 1000000000.45', '1000000000.45')
    })
  })

  describe('#rawValue()', () => {
    const checkValue = (input, expected) => {
      const solution = new QuizFormulaSolution(input)
      expect(solution.rawValue()).toBe(expected)
    }

    test('returns the numeric form of the right-hand side of the formula', () => {
      checkValue('= 0', 0)
      checkValue('= 2.5', 2.5)
      checkValue('= 17', 17)
      checkValue('= -25.12', -25.12)
      checkValue('= 1000000000.45', 1000000000.45)
    })

    test('returns NaN for non-numeric text', () => {
      const solution = new QuizFormulaSolution('= NotReallyValuable')
      expect(Number.isNaN(solution.rawValue())).toBe(true)
    })

    test('returns NaN for null', () => {
      const solution = new QuizFormulaSolution(null)
      expect(Number.isNaN(solution.rawValue())).toBe(true)
    })

    test('returns NaN for undefined', () => {
      const solution = new QuizFormulaSolution(undefined)
      expect(Number.isNaN(solution.rawValue())).toBe(true)
    })
  })

  describe('#isValid()', () => {
    const checkSolutionValidity = (input, validity) => {
      const solution = new QuizFormulaSolution(input)
      expect(solution.isValid()).toBe(validity)
    }

    test('returns true for decimals', () => {
      checkSolutionValidity('= 2.5', true)
    })

    test('returns true for 0', () => {
      checkSolutionValidity('= 0', true)
    })

    test('returns false for formulas not starting with =', () => {
      checkSolutionValidity('0', false)
    })

    test('returns false for NaN', () => {
      checkSolutionValidity('= NaN', false)
    })

    test('returns false for Infinity', () => {
      checkSolutionValidity('= Infinity', false)
    })

    test('returns false for non-numeric text', () => {
      checkSolutionValidity('= ABCDE', false)
    })
  })
})
