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

import React from 'react'
import {render, screen, within} from '@testing-library/react'

import {speedGraderUrl} from '../../../assignment/AssignmentApi'
import Grid from '../Grid'
import GridRow from '../GridRow'
import {STARTED, SUCCESS} from '../../../grades/GradeActions'

const ActualGridRow = jest.requireActual('../GridRow').default
jest.mock('../GridRow', props => {
  return jest.fn(properties => {
    return <ActualGridRow {...properties} />
  })
})

describe('GradeSummary Grid', () => {
  let props

  function speedGraderUrlFor(studentId) {
    return speedGraderUrl('1201', '2301', {anonymousStudents: false, studentId})
  }

  afterEach(() => {
    jest.clearAllMocks()
  })

  beforeEach(() => {
    props = {
      horizontalScrollRef: () => {},
      disabledCustomGrade: false,
      finalGrader: {
        graderId: 'teach',
        id: '1105',
      },
      graders: [
        {graderId: '1101', graderName: 'Miss Frizzle'},
        {graderId: '1102', graderName: 'Mr. Keating'},
      ],
      grades: {
        1111: {
          1101: {
            grade: 'A',
            graderId: '1101',
            id: '4601',
            score: 10,
            selected: false,
            studentId: '1111',
          },
          1102: {
            grade: 'B',
            graderId: '1102',
            id: '4602',
            score: 8.9,
            selected: false,
            studentId: '1111',
          },
        },
        1112: {
          1102: {
            grade: 'C',
            graderId: '1102',
            id: '4603',
            score: 7.8,
            selected: false,
            studentId: '1112',
          },
        },
        1113: {
          1101: {
            grade: 'A',
            graderId: '1101',
            id: '4604',
            score: 10,
            selected: false,
            studentId: '1113',
          },
        },
      },
      onGradeSelect: jest.fn(),
      rows: [
        {speedGraderUrl: speedGraderUrlFor('1111'), studentId: '1111', studentName: 'Adam Jones'},
        {speedGraderUrl: speedGraderUrlFor('1112'), studentId: '1112', studentName: 'Betty Ford'},
        {speedGraderUrl: speedGraderUrlFor('1113'), studentId: '1113', studentName: 'Charlie Xi'},
        {speedGraderUrl: speedGraderUrlFor('1114'), studentId: '1114', studentName: 'Dana Smith'},
      ],
      selectProvisionalGradeStatuses: {
        1111: SUCCESS,
        1112: STARTED,
      },
    }
  })

  test('includes a column header for the student name column', () => {
    render(<Grid {...props} />)
    expect(screen.getByRole('columnheader', {name: 'Student'})).toBeInTheDocument()
  })

  test('includes a column header for each grader', () => {
    render(<Grid {...props} />)
    expect(
      screen
        .getAllByRole('columnheader')
        .filter(header => header.textContent.match(/Miss Frizzle|Mr. Keating/)).length
    ).toBe(2)
  })

  test('includes a column header for the final grade column', () => {
    render(<Grid {...props} />)
    expect(screen.getByRole('columnheader', {name: /final grade/i})).toBeInTheDocument()
  })

  test('displays the grader names in the column headers', () => {
    render(<Grid {...props} />)
    const headers = screen
      .getAllByRole('columnheader')
      .filter(header => header.textContent.match(/Miss Frizzle|Mr. Keating/))
    expect(headers.map(header => header.textContent)).toEqual(['Miss Frizzle', 'Mr. Keating'])
  })

  test('includes a GridRow for each student', () => {
    render(<Grid {...props} />)
    const rows = within(screen.getAllByRole('rowgroup')[1]).getAllByRole('row')
    expect(rows.length).toBe(4)
  })

  test('sends disabledCustomGrade to each GridRow', () => {
    render(<Grid {...props} />)
    const rowCalls = GridRow.mock.calls.filter(call => !call[0].disabledCustomGrade)
    expect(rowCalls.length).toBe(4)
  })

  test('sends finalGrader to each GridRow', () => {
    render(<Grid {...props} />)
    const rowCalls = GridRow.mock.calls.filter(call => !!call[0].finalGrader)
    expect(rowCalls.length).toBe(4)
  })

  test('sends graders to each GridRow', () => {
    render(<Grid {...props} />)
    const rowCalls = GridRow.mock.calls
    expect(
      rowCalls.map(row => row[0].graders.map(grader => grader.graderName)).flat()
    ).toStrictEqual([
      'Miss Frizzle',
      'Mr. Keating',
      'Miss Frizzle',
      'Mr. Keating',
      'Miss Frizzle',
      'Mr. Keating',
      'Miss Frizzle',
      'Mr. Keating',
    ])
  })

  test('sends onGradeSelect to each GridRow', () => {
    render(<Grid {...props} />)
    const rowCalls = GridRow.mock.calls.filter(call => !!call[0].onGradeSelect)
    expect(rowCalls.length).toBe(4)
  })

  test('sends student-specific grades to each GridRow', () => {
    render(<Grid {...props} />)
    const firstStudentGrade = GridRow.mock.calls[0][0].grades
    expect(Object.keys(firstStudentGrade)).toStrictEqual(['1101', '1102'])
  })

  test('sends student-specific select provisional grade statuses to each GridRow', () => {
    render(<Grid {...props} />)
    const rowCalls = GridRow.mock.calls.filter(
      call => call[0].selectProvisionalGradeStatus == STARTED
    )
    expect(rowCalls.length).toBe(1)
  })

  test('sends the related row to each GridRow', () => {
    render(<Grid {...props} />)
    const rowCalls = GridRow.mock.calls.filter(call => !!call[0].row)
    expect(rowCalls.length).toBe(4)
  })
})
