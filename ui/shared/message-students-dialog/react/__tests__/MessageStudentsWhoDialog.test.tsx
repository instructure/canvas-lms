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

import React from 'react'
import {fireEvent, render} from '@testing-library/react'
import MessageStudentsWhoDialog, {
  Assignment,
  Props as ComponentProps,
  Student
} from '../MessageStudentsWhoDialog'

const students: Student[] = [
  {
    id: '100',
    name: 'Adam Jones',
    sortableName: 'Jones, Adam'
  },
  {
    id: '101',
    name: 'Betty Ford',
    sortableName: 'Ford, Betty'
  },
  {
    id: '102',
    name: 'Charlie Xi',
    sortableName: 'Xi, Charlie'
  },
  {
    id: '103',
    name: 'Dana Smith',
    sortableName: 'Smith, Dana'
  }
]

const scoredAssignment: Assignment = {
  gradingType: 'points',
  id: '100',
  name: 'A pointed assignment',
  nonDigitalSubmission: false
}

const ungradedAssignment: Assignment = {
  gradingType: 'not_graded',
  id: '200',
  name: 'A pointless assignment',
  nonDigitalSubmission: false
}

const passFailAssignment: Assignment = {
  gradingType: 'pass_fail',
  id: '300',
  name: 'A pass-fail assignment',
  nonDigitalSubmission: false
}

const unsubmittableAssignment: Assignment = {
  gradingType: 'no_submission',
  id: '400',
  name: 'An unsubmittable assignment',
  nonDigitalSubmission: true
}

function makeProps(overrides: object = {}): ComponentProps {
  return {
    assignment: scoredAssignment,
    students,
    onClose: () => {},
    ...overrides
  }
}

describe('MessageStudentsWhoDialog', () => {
  it('hides the list of students initially', () => {
    const {queryByRole} = render(<MessageStudentsWhoDialog {...makeProps()} />)
    expect(queryByRole('table')).not.toBeInTheDocument()
  })

  it('shows students sorted by sortable name when the table is shown', () => {
    const {getByRole, getAllByRole} = render(<MessageStudentsWhoDialog {...makeProps()} />)

    fireEvent.click(getByRole('button', {name: 'Show all recipients'}))
    expect(getByRole('table')).toBeInTheDocument()

    const tableRows = getAllByRole('row') as HTMLTableRowElement[]
    const studentCells = tableRows.map(row => row.cells[0])
    // first cell will be the header
    expect(studentCells).toHaveLength(5)
    expect(studentCells[0]).toHaveTextContent('Students')
    expect(studentCells[1]).toHaveTextContent('Betty Ford')
    expect(studentCells[2]).toHaveTextContent('Adam Jones')
    expect(studentCells[3]).toHaveTextContent('Dana Smith')
    expect(studentCells[4]).toHaveTextContent('Charlie Xi')
  })

  it('includes the total number of students in the checkbox label', () => {
    const {getByRole} = render(<MessageStudentsWhoDialog {...makeProps()} />)
    expect(getByRole('checkbox', {name: /Students/})).toHaveAccessibleName('4 Students')
  })

  describe('available criteria', () => {
    it('includes score-related options but no "Marked incomplete" option for point-based assignments', () => {
      const {getAllByRole, getByLabelText} = render(<MessageStudentsWhoDialog {...makeProps()} />)

      fireEvent.click(getByLabelText(/For students who/))
      const criteriaLabels = getAllByRole('option').map(option => option.textContent)
      expect(criteriaLabels).toContain('Scored more than')
      expect(criteriaLabels).toContain('Scored less than')
      expect(criteriaLabels).not.toContain('Marked incomplete')
    })

    it('includes "Marked incomplete" but no score-related options for pass-fail assignments', () => {
      const {getAllByRole, getByLabelText} = render(
        <MessageStudentsWhoDialog {...makeProps({assignment: passFailAssignment})} />
      )

      fireEvent.click(getByLabelText(/For students who/))
      const criteriaLabels = getAllByRole('option').map(option => option.textContent)
      expect(criteriaLabels).toContain('Marked incomplete')
      expect(criteriaLabels).not.toContain('Scored more than')
      expect(criteriaLabels).not.toContain('Scored less than')
    })

    it('does not include "Marked incomplete" or score-related options for ungraded assignments', () => {
      const {getAllByRole, getByLabelText} = render(
        <MessageStudentsWhoDialog {...makeProps({assignment: ungradedAssignment})} />
      )

      fireEvent.click(getByLabelText(/For students who/))
      const criteriaLabels = getAllByRole('option').map(option => option.textContent)
      expect(criteriaLabels).not.toContain('Marked incomplete')
      expect(criteriaLabels).not.toContain('Scored more than')
      expect(criteriaLabels).not.toContain('Scored less than')
    })

    it('includes "Have not yet submitted" if the assignment accepts digital submissions', () => {
      const {getAllByRole, getByLabelText} = render(<MessageStudentsWhoDialog {...makeProps()} />)

      fireEvent.click(getByLabelText(/For students who/))
      const criteriaLabels = getAllByRole('option').map(option => option.textContent)
      expect(criteriaLabels).toContain('Have not yet submitted')
    })

    it('does not include "Have not yet submitted" if the assignment does not accept digital submissions', () => {
      const {getAllByRole, getByLabelText} = render(
        <MessageStudentsWhoDialog {...makeProps({assignment: unsubmittableAssignment})} />
      )

      fireEvent.click(getByLabelText(/For students who/))
      const criteriaLabels = getAllByRole('option').map(option => option.textContent)
      expect(criteriaLabels).not.toContain('Have not yet submitted')
    })
  })

  describe('cutoff input', () => {
    it('is shown only when "Scored more than" or "Scored less than" is selected', () => {
      const {getByLabelText, getByRole, queryByLabelText} = render(
        <MessageStudentsWhoDialog {...makeProps()} />
      )

      expect(queryByLabelText('Enter score cutoff')).not.toBeInTheDocument()

      const selector = getByLabelText(/For students who/)

      fireEvent.click(selector)
      fireEvent.click(getByRole('option', {name: 'Scored more than'}))
      expect(getByLabelText('Enter score cutoff')).toBeInTheDocument()

      fireEvent.click(selector)
      fireEvent.click(getByRole('option', {name: 'Scored less than'}))
      expect(getByLabelText('Enter score cutoff')).toBeInTheDocument()

      fireEvent.click(selector)
      fireEvent.click(getByRole('option', {name: 'Reassigned'}))
      expect(queryByLabelText('Enter score cutoff')).not.toBeInTheDocument()
    })
  })
})
