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

import QuizFormulaSolution from 'quiz_formula_solution'

QUnit.module('QuizForumlaSolution', {
  setup() {},
  teardown() {}
})

test('constructor: property setting', () => {
  const solution = new QuizFormulaSolution('= 0')
  equal(solution.result, '= 0')
})
const checkValue = function(input, expected) {
  const solution = new QuizFormulaSolution(input)
  equal(solution.rawValue(), expected)
}
const checkText = function(input, expected) {
  const solution = new QuizFormulaSolution(input)
  equal(solution.rawText(), expected)
}
test('can parse out raw values', () => {
  checkValue('= 0', 0)
  checkValue('= 2.5', 2.5)
  checkValue('= 17', 17)
  checkValue('= -25.12', -25.12)
  return checkValue('= 1000000000.45', 1000000000.45)
})

test('parsing out text of value', () => {
  checkText('= 0', '0')
  checkText('= 2.5', '2.5')
  checkText('= 17', '17')
  checkText('= -25.12', '-25.12')
  return checkText('= 1000000000.45', '1000000000.45')
})

test('parses bad numbers effectively', () => {
  let solution = new QuizFormulaSolution('= NotReallyValuable')
  ok(isNaN(solution.rawValue()))
  solution = new QuizFormulaSolution(null)
  ok(isNaN(solution.rawValue()))
  solution = new QuizFormulaSolution(undefined)
  ok(isNaN(solution.rawValue()))
})

QUnit.module('QuizForumlaSolution#isValid', {
  setup() {},
  teardown() {}
})
const checkSolutionValidity = function(input, validity) {
  const solution = new QuizFormulaSolution(input)
  equal(solution.isValid(), validity)
}
test('false without starting with =', () => checkSolutionValidity('0', false))

test('false if NaN', () => checkSolutionValidity('= NaN', false))

test('false if Infinity', () => checkSolutionValidity('= Infinity', false))

test('false if not a number', () => checkSolutionValidity('= ABCDE', false))

test('true for valid number', () => checkSolutionValidity('= 2.5', true))

test('true for 0', () => checkSolutionValidity('= 0', true))
