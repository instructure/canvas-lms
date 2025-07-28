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

import {
  getGradeAsPercent,
  getStudentGradeForColumn,
  idArraysEqual,
  postPolicyChangeable,
} from '../Gradebook.utils'

describe('postPolicyChangeable', () => {
  it('returns false if the assignment is null', () => {
    expect(postPolicyChangeable(null)).toStrictEqual(false)
  })

  it('returns false if the assignment is undefined', () => {
    expect(postPolicyChangeable(undefined)).toStrictEqual(false)
  })

  it('returns false if the assignment is anonymizing students', () => {
    expect(postPolicyChangeable({anonymize_students: true})).toStrictEqual(false)
  })

  it('returns true if the assignment is not anonymizing students', () => {
    expect(postPolicyChangeable({anonymize_students: false})).toStrictEqual(true)
  })
})

describe('getGradeAsPercent', () => {
  it('returns a percent for a grade with points possible', () => {
    const percent = getGradeAsPercent({score: 5, possible: 10})
    expect(percent).toStrictEqual(0.5)
  })

  it('returns null for a grade with no points possible', () => {
    const percent = getGradeAsPercent({score: 5, possible: 0})
    expect(percent).toStrictEqual(null)
  })

  it('returns 0 for a grade with a null score', () => {
    const percent = getGradeAsPercent({score: null, possible: 10})
    expect(percent).toStrictEqual(0)
  })

  it('returns 0 for a grade with an undefined score', () => {
    const percent = getGradeAsPercent({score: undefined, possible: 10})
    expect(percent).toStrictEqual(0)
  })
})

describe('getStudentGradeForColumn', () => {
  it('returns the grade stored on the student for the column id', () => {
    const student = {total_grade: {score: 5, possible: 10}}
    const grade = getStudentGradeForColumn(student, 'total_grade')
    expect(grade).toEqual(student.total_grade)
  })

  it('returns an empty grade when the student has no grade for the column id', () => {
    const student = {total_grade: undefined}
    const grade = getStudentGradeForColumn(student, 'total_grade')
    expect(grade.score).toStrictEqual(null)
    expect(grade.possible).toStrictEqual(0)
  })
})

describe('idArraysEqual', () => {
  it('returns true when passed two sets of ids with the same contents', () => {
    expect(idArraysEqual(['1', '2'], ['1', '2'])).toStrictEqual(true)
  })

  it('returns true when passed two sets of ids with the same contents in different order', () => {
    expect(idArraysEqual(['2', '1'], ['1', '2'])).toStrictEqual(true)
  })

  it('returns true when passed two empty arrays', () => {
    expect(idArraysEqual([], [])).toStrictEqual(true)
  })

  it('returns false when passed two different sets of ids', () => {
    expect(idArraysEqual(['1'], ['1', '2'])).toStrictEqual(false)
  })
})
