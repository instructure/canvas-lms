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
import {render, screen} from '@testing-library/react'
import GridRow from '../GridRow'

describe('GradeSummary GridRow', () => {
  let props

  beforeEach(() => {
    props = {
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
      onGradeSelect: jest.fn(),
      row: {
        speedGraderUrl: 'http://example.com/speedGrader/1111',
        studentId: '1111',
        studentName: 'Adam Jones',
      },
      selectProvisionalGradeStatus: 'STARTED',
    }
  })

  const renderComponent = () =>
    render(
      <table>
        <tbody>
          <GridRow {...props} />
        </tbody>
      </table>
    )

  test('displays the student name in the row header', () => {
    renderComponent()
    expect(screen.getByText('Adam Jones')).toBeInTheDocument()
  })

  test('links the student name to the student in SpeedGrader', () => {
    renderComponent()
    const link = screen.getByRole('link', {name: 'Adam Jones'})
    expect(link).toHaveAttribute('href', props.row.speedGraderUrl)
  })

  test('includes a cell for each grader', () => {
    renderComponent()
    const cells = screen
      .getAllByRole('cell')
      .filter(cell => cell.className.match(/GradesGrid__ProvisionalGradeCell/))
    expect(cells.length).toBe(props.graders.length)
  })

  test('displays the score of a provisional grade in the matching cell', () => {
    renderComponent()
    expect(screen.getByText('8.9')).toBeInTheDocument()
  })

  test('displays zero scores', () => {
    props.grades[1101].score = 0
    renderComponent()
    expect(screen.getByText('0')).toBeInTheDocument()
  })

  test('displays "–" (en dash) when the student grade for a given grader was cleared', () => {
    props.grades[1101].score = null
    renderComponent()
    expect(screen.getByText('–')).toBeInTheDocument()
  })

  test('displays "–" (en dash) when the student was not graded by a given grader', () => {
    delete props.grades[1101]
    renderComponent()
    expect(screen.getByText('–')).toBeInTheDocument()
  })

  test('displays "–" (en dash) when the student has no provisional grades', () => {
    props.grades = {}
    renderComponent()
    expect(screen.getAllByText('–').length).toBe(2)
  })
})
