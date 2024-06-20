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

import ScoreToGradeHelper from '../ScoreToGradeHelper'

describe('ScoreToGradeHelper#scoreToGrade', () => {
  test('formats score as empty string when score is null', () => {
    const grade = ScoreToGradeHelper.scoreToGrade(null)
    expect(grade).toBe('')
  })

  test('formats score as points when grading_type is "points"', () => {
    const grade = ScoreToGradeHelper.scoreToGrade(12.34, {grading_type: 'points'})
    expect(grade).toBe('12.34')
  })

  test('formats score as percentage when grading_type is "percent"', () => {
    const grade = ScoreToGradeHelper.scoreToGrade(12.34, {
      grading_type: 'percent',
      points_possible: 50,
    })
    expect(grade).toBe('24.68%')
  })

  test('formats score as empty string when grading_type is "percent" and assignment has no points_possible', () => {
    const grade = ScoreToGradeHelper.scoreToGrade(12.34, {
      grading_type: 'percent',
      points_possible: 0,
    })
    expect(grade).toBe('')
  })

  test('formats score as "complete" when grading_type is "pass_fail" and score is nonzero', () => {
    const grade = ScoreToGradeHelper.scoreToGrade(12.34, {grading_type: 'pass_fail'})
    expect(grade).toBe('complete')
  })

  test('formats score as "incomplete" when grading_type is "pass_fail" and score is zero', () => {
    const grade = ScoreToGradeHelper.scoreToGrade(0, {grading_type: 'pass_fail'})
    expect(grade).toBe('incomplete')
  })

  test('formats score as empty string when grading_type is "letter_grade" and no gradingScheme given', () => {
    const grade = ScoreToGradeHelper.scoreToGrade(12.34, {
      grading_type: 'letter_grade',
      points_possible: 10,
    })
    expect(grade).toBe('')
  })

  test('formats score as empty string when grading_type is "letter_grade" and assignment has no points_possible', () => {
    const grade = ScoreToGradeHelper.scoreToGrade(12.34, {grading_type: 'letter_grade'}, [
      ['A', 0.9],
      ['B', 0.8],
      ['C', 0.7],
      ['F', 0],
    ])
    expect(grade).toBe('')
  })

  test('formats score as letter grade when grading_type is "letter_grade" and gradingScheme given', () => {
    const grade = ScoreToGradeHelper.scoreToGrade(
      7,
      {grading_type: 'letter_grade', points_possible: 10},
      [
        ['A', 0.9],
        ['B', 0.8],
        ['C', 0.7],
        ['F', 0],
      ]
    )
    expect(grade).toBe('C')
  })
})
