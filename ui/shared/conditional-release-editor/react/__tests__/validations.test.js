/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {validateScores} from '../validations'
import {List, Map} from 'immutable'

const defaultScoringInfo = () => {
  return Map({
    grading_type: 'points',
    min_score: null,
    submission_types: 'on_paper',
    points_possible: 1000,
    grading_scheme: null,
    max_score: null,
    title: 'Point Assignment',
    id: '6',
    description: '',
  })
}

const defaultScoringInfoLetter = () => {
  return Map({
    grading_type: 'letter_grade',
    min_score: null,
    submission_types: 'on_paper',
    points_possible: 10,
    grading_scheme: Map({
      A: 0.94,
      B: 0.84,
      C: 0.74,
      D: 0.64,
      F: 0,
      'D+': 0.67,
      'C+': 0.77,
      'B+': 0.87,
      'A-': 0.9,
      'B-': 0.8,
      'D-': 0.61,
      'C-': 0.7,
    }),
    max_score: null,
    title: 'Letter Assignment',
    id: '5',
    description: '',
  })
}

describe('validateScores', () => {
  it('allows scores within bounds', () => {
    const errors = validateScores(
      List(['1.0', '.9', '.8', '.2', '.111', '0.100', '0']),
      defaultScoringInfo()
    )
    expect(errors.toJS()).toEqual([null, null, null, null, null, null, null])
  })

  it('allows scores with similar ranges', () => {
    const errors = validateScores(
      List(['1.0', '1.0', '1.0', '1.0', '1.0', '1.0', '1.0']),
      defaultScoringInfo()
    )
    expect(errors.toJS()).toEqual([null, null, null, null, null, null, null])
  })

  it('allows scores with similar ranges and shows correct errors', () => {
    const errors = validateScores(
      List(['1.0', '1.0', '1.0', '1.0', '1.0', '2.0', '1.0']),
      defaultScoringInfo()
    )
    expect(errors.toJS()).toEqual([null, null, null, null, null, 'number is too large', null])
  })

  it('allows scores with close bounds', () => {
    const errors = validateScores(List(['1.0', '0.999', '0.998']), defaultScoringInfo())
    expect(errors.toJS()).toEqual([null, null, null])
  })

  it('allows scores within bounds for letters', () => {
    const errors = validateScores(
      List(['1.0', '.9', '.8', '.2', '.111', '0.100', '0']),
      defaultScoringInfoLetter()
    )
    expect(errors.toJS()).toEqual([null, null, null, null, null, null, null])
  })

  it('allows numbers as well as strings for scores', () => {
    const errors = validateScores(List([1, '0.3', 0.2, '0.1', 0]), defaultScoringInfo())
    expect(errors.toJS()).toEqual([null, null, null, null, null])
  })

  it('allows numbers as well as strings for scores for letter_grades', () => {
    const errors = validateScores(List([1, '0.3', 0.2, '0.1', 0]), defaultScoringInfoLetter())
    expect(errors.toJS()).toEqual([null, null, null, null, null])
  })

  const expectAllInvalid = (errorExpression, ...args) => {
    args.forEach(val => {
      const errors = validateScores(List(['1.00', val, '.20']))
      expect(errors.get(1)).toMatch(
        errorExpression,
        'value ' + val + ' should have error matching ' + errorExpression
      )
    })
  }

  const expectAllInvalidLetters = (errorExpression, ...args) => {
    args.forEach(val => {
      const errors = validateScores(List(['1.0', val, '.2']), defaultScoringInfoLetter())
      expect(errors.get(1)).toMatch(
        errorExpression,
        'value ' + val + ' should have error matching ' + errorExpression
      )
    })
  }

  it('reports error for really weird input (non-number, non-string)', () => {
    expectAllInvalid(/./, true, () => 'foo', {}, [], /foo/)
  })

  it('reports error for really weird input (non-number, non-string) for letter-grades', () => {
    expectAllInvalidLetters(/./, true, () => 'foo', {}, [], /foo/)
  })

  it('requires input to be numeric', () => {
    expectAllInvalid(/number/, 'b', '354a', Infinity, NaN)
  })

  it('requires the input to be within bounds', () => {
    expectAllInvalid(/too/, '1.1', '1.105', '-1')
    expectAllInvalidLetters(/too/, '1.1', '1.105', '-1')
  })

  it('requires the input to not be blank', () => {
    expectAllInvalid(/empty/, null, '')
    expectAllInvalidLetters(/empty/, null, '')
  })

  it('requires scores be in order', () => {
    const errors = validateScores(List(['1.0', '.5', '.7']))
    expect(errors.get(0)).toEqual(null)
    expect(errors.get(1)).toMatch(/order/)
    expect(errors.get(2)).toMatch(/order/)
  })

  it('does not report out of order when one of the unordered has another error', () => {
    const errors = validateScores(List(['.8', '-1', '.3']))
    expect(errors.get(1)).toMatch(/./)
    expect(errors.get(2)).toEqual(null)
  })

  it('can report multiple kinds of errors on the same input', () => {
    const errors = validateScores(List(['1.02', '.30', '.70', 'babel', '-.99', '', '.20', '.90']))
    errors.forEach(e => {
      expect(e).toMatch(/./)
    })
  })
})
