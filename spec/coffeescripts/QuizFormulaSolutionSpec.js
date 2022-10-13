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

import QuizFormulaSolution from 'ui/features/quizzes/quiz_formula_solution'

QUnit.module('QuizFormulaSolution', () => {
  test('sets .result to the given formula', () => {
    const solution = new QuizFormulaSolution('= 0')
    equal(solution.result, '= 0')
  })

  QUnit.module('#rawText()', () => {
    function checkText(input, expected) {
      const solution = new QuizFormulaSolution(input)
      equal(solution.rawText(), expected)
    }

    test('returns the right-hand side of the formula', () => {
      checkText('= 0', '0')
      checkText('= 2.5', '2.5')
      checkText('= 17', '17')
      checkText('= -25.12', '-25.12')
      checkText('= 1000000000.45', '1000000000.45')
    })
  })

  QUnit.module('#rawValue()', () => {
    function checkValue(input, expected) {
      const solution = new QuizFormulaSolution(input)
      equal(solution.rawValue(), expected)
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
      ok(Number.isNaN(solution.rawValue()))
    })

    test('returns NaN for null', () => {
      const solution = new QuizFormulaSolution(null)
      ok(Number.isNaN(solution.rawValue()))
    })

    test('returns NaN for undefined', () => {
      const solution = new QuizFormulaSolution(undefined)
      ok(Number.isNaN(solution.rawValue()))
    })
  })

  QUnit.module('#isValid()', () => {
    function checkSolutionValidity(input, validity) {
      const solution = new QuizFormulaSolution(input)
      equal(solution.isValid(), validity)
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
