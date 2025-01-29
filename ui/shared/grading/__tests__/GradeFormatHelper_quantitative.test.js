/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {useScope as createI18nScope} from '@canvas/i18n'
import numberHelper from '@canvas/i18n/numberHelper'
import GradeFormatHelper from '../GradeFormatHelper'

const I18n = createI18nScope('sharedGradeFormatHelper')

describe('GradeFormatHelper.formatGrade() with Restrict_quantitative_data', () => {
  const scheme = [
    ['A', 0.9],
    ['B', 0.8],
    ['C', 0.7],
    ['D', 0.6],
    ['F', 0.5],
  ]

  const defaultProps = ({
    pointsPossible = 100,
    restrict_quantitative_data = true,
    score = null,
    grading_scheme = scheme,
  } = {}) => ({
    pointsPossible,
    restrict_quantitative_data,
    grading_scheme,
    score,
  })

  const formatGrade = (grade, options = defaultProps()) =>
    GradeFormatHelper.formatGrade(grade, options)

  beforeEach(() => {
    jest.spyOn(numberHelper, 'validate').mockImplementation(val => !Number.isNaN(parseFloat(val)))
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('returns the set grade value if it is already a letter_grade', () => {
    expect(formatGrade('C+')).toBe('C+')
  })

  it('returns the set grade value if score and points possible are 0', () => {
    const gradeOptions = defaultProps({score: 0, pointsPossible: 0})
    expect(formatGrade('C+', gradeOptions)).toBe('C+')
  })

  it('returns the correct value for complete/incomplete grade', () => {
    const gradeOptions = defaultProps({score: 10, pointsPossible: 0})
    expect(formatGrade('complete', gradeOptions)).toBe('complete')
  })

  it('returns excused if the grade is excused but graded', () => {
    const gradeOptions = defaultProps({score: 50})
    expect(formatGrade('EX', gradeOptions)).toBe('Excused')
  })

  it('returns null if points possible is 0, and grade is null', () => {
    const gradeOptions = defaultProps({score: null, pointsPossible: 0})
    expect(formatGrade(null, gradeOptions)).toBeNull()
  })

  it('returns A if points possible is 0, and the score is greater than 0', () => {
    const gradeOptions = defaultProps({score: 1, pointsPossible: 0})
    expect(formatGrade('1', gradeOptions)).toBe('A')
  })

  it('converts percentage to letter-grade', () => {
    const gradeOptions = defaultProps({score: 8.5, pointsPossible: 10})
    expect(formatGrade('85%', gradeOptions)).toBe('B')
  })

  it('returns the correct grading scheme based on points and score', () => {
    const gradeOptions = defaultProps({score: 50})
    expect(formatGrade('50', gradeOptions)).toBe('F')

    gradeOptions.score = 60
    expect(formatGrade('60', gradeOptions)).toBe('D')

    gradeOptions.score = 70
    expect(formatGrade('70', gradeOptions)).toBe('C')

    gradeOptions.score = 80
    expect(formatGrade('80', gradeOptions)).toBe('B')

    gradeOptions.score = 90
    expect(formatGrade('90', gradeOptions)).toBe('A')
  })

  it('returns the correct letter grade based on different points possible', () => {
    const gradeOptions = defaultProps({score: 5, pointsPossible: 3})
    expect(formatGrade('5', gradeOptions)).toBe('A')
  })
})
