// @ts-nocheck
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
import {fireEvent, render, waitFor} from '@testing-library/react'
import {within} from '@testing-library/dom'
import MessageStudentsWhoDialog, {
  Assignment,
  Props as ComponentProps,
  Student,
} from '../MessageStudentsWhoDialog'
import {MockedProvider} from '@apollo/react-testing'
import mockGraphqlQuery from '@canvas/graphql-query-mock'
import {createCache} from '@canvas/apollo'
import {OBSERVER_ENROLLMENTS_QUERY} from '../../graphql/Queries'

const students: Student[] = [
  {
    id: '100',
    name: 'Betty Ford',
    grade: undefined,
    redoRequest: false,
    sortableName: 'Ford, Betty',
    score: undefined,
    submittedAt: undefined,
    excused: false,
  },
  {
    id: '101',
    name: 'Adam Jones',
    grade: undefined,
    redoRequest: false,
    sortableName: 'Jones, Adam',
    score: undefined,
    submittedAt: undefined,
    excused: false,
  },
  {
    id: '102',
    name: 'Charlie Xi',
    grade: undefined,
    redoRequest: false,
    sortableName: 'Xi, Charlie',
    score: undefined,
    submittedAt: undefined,
    excused: false,
  },
  {
    id: '103',
    name: 'Dana Smith',
    grade: undefined,
    redoRequest: false,
    sortableName: 'Smith, Dana',
    score: undefined,
    submittedAt: undefined,
    excused: false,
  },
]

const scoredAssignment: Assignment = {
  allowedAttempts: 3,
  courseId: '1',
  dueDate: new Date(),
  gradingType: 'points',
  id: '100',
  name: 'A pointed assignment',
  submissionTypes: ['online_text_entry'],
}

const ungradedAssignment: Assignment = {
  allowedAttempts: 1,
  courseId: '1',
  gradingType: 'not_graded',
  dueDate: null,
  id: '200',
  name: 'A pointless assignment',
  submissionTypes: ['online_text_entry'],
}

const passFailAssignment: Assignment = {
  allowedAttempts: -1,
  courseId: '1',
  dueDate: null,
  gradingType: 'pass_fail',
  id: '300',
  name: 'A pass-fail assignment',
  submissionTypes: ['online_text_entry'],
}

const unsubmittableAssignment: Assignment = {
  allowedAttempts: 3,
  courseId: '1',
  dueDate: new Date(),
  gradingType: 'no_submission',
  id: '400',
  name: 'An unsubmittable assignment',
  submissionTypes: ['on_paper'],
}

function makeProps(overrides: object = {}): ComponentProps {
  return {
    assignment: scoredAssignment,
    students,
    onClose: () => {},
    onSend: () => {},
    messageAttachmentUploadFolderId: '1',
    userId: '345',
    ...overrides,
  }
}

async function makeMocks(overrides = [], sameStudent = false) {
  const variables = {courseId: '1', studentIds: ['100', '101', '102', '103']}
  const allOverrides = [...overrides, {EnrollmentType: 'ObserverEnrollment'}]

  const resultQuery = await mockGraphqlQuery(OBSERVER_ENROLLMENTS_QUERY, allOverrides, variables)

  const nodes = resultQuery.data?.course.enrollmentsConnection.nodes

  nodes.forEach(function (node, index) {
    node.user.name = 'Observer' + index
    if (sameStudent) {
      node.associatedUser._id = students[0].id
    } else {
      node.associatedUser._id = students[index].id
    }
  })

  return [
    {
      request: {
        query: OBSERVER_ENROLLMENTS_QUERY,
        variables: {
          courseId: '1',
          studentIds: ['100', '101', '102', '103'],
        },
      },
      result: resultQuery,
    },
  ]
}

function allObserverNames() {
  return ['Observer0', 'Observer1']
}

function expectToBeSelected(cell) {
  const selectedElement = within(cell).getByTestId('item-selected')
  const unselectedElement = within(cell).queryByTestId('item-unselected')
  expect(selectedElement).toBeInTheDocument()
  expect(unselectedElement).not.toBeInTheDocument()
}

function expectToBeUnselected(cell) {
  const selectedElement = within(cell).queryByTestId('item-selected')
  const unselectedElement = within(cell).getByTestId('item-unselected')
  expect(selectedElement).not.toBeInTheDocument()
  expect(unselectedElement).toBeInTheDocument()
}

// unskip in EVAL-2535
describe.skip('MessageStudentsWhoDialog', () => {
  it('hides the list of students and observers initially', async () => {
    const mocks = await makeMocks()

    const {queryByRole} = render(
      <MockedProvider mocks={mocks} cache={createCache()}>
        <MessageStudentsWhoDialog {...makeProps()} />
      </MockedProvider>
    )
    await waitFor(() => {
      expect(queryByRole('table')).not.toBeInTheDocument()
    })
  })

  it('shows students sorted by sortable name when the table is shown', async () => {
    const mocks = await makeMocks()

    const {getByRole, getAllByRole, findByRole} = render(
      <MockedProvider mocks={mocks} cache={createCache()}>
        <MessageStudentsWhoDialog {...makeProps()} />
      </MockedProvider>
    )

    const button = await findByRole('button', {name: 'Show all recipients'})
    fireEvent.click(button)
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

  it('shows observers sorted by the sortable name of the associated user when the table is shown', async () => {
    const mocks = await makeMocks()

    const {findByRole, getByRole, getAllByRole} = render(
      <MockedProvider mocks={mocks} cache={createCache()}>
        <MessageStudentsWhoDialog {...makeProps()} />
      </MockedProvider>
    )

    const button = await findByRole('button', {name: 'Show all recipients'})
    fireEvent.click(button)
    expect(getByRole('table')).toBeInTheDocument()

    const tableRows = getAllByRole('row') as HTMLTableRowElement[]
    const observerCells = tableRows.map(row => row.cells[1])
    // first cell will be the header
    expect(observerCells).toHaveLength(5)
    expect(observerCells[0]).toHaveTextContent('Observers')
    expect(observerCells[1]).toHaveTextContent('Observer0')
    expect(observerCells[2]).toHaveTextContent('Observer1')
    expect(observerCells[3]).toHaveTextContent('')
    expect(observerCells[4]).toHaveTextContent('')
  })

  it('shows observers in the same cell sorted by the sortable name when observing the same student', async () => {
    const mocks = await makeMocks([], true)

    const {findByRole, getByRole, getAllByRole} = render(
      <MockedProvider mocks={mocks} cache={createCache()}>
        <MessageStudentsWhoDialog {...makeProps()} />
      </MockedProvider>
    )
    const button = await findByRole('button', {name: 'Show all recipients'})
    fireEvent.click(button)
    expect(getByRole('table')).toBeInTheDocument()

    const tableRows = getAllByRole('row') as HTMLTableRowElement[]
    const observerCells = tableRows.map(row => row.cells[1])
    // first cell will be the header
    expect(observerCells).toHaveLength(5)
    expect(observerCells[0]).toHaveTextContent('Observers')
    expect(observerCells[1]).toHaveTextContent('Observer0Observer1')
    expect(observerCells[2]).toHaveTextContent('')
    expect(observerCells[3]).toHaveTextContent('')
    expect(observerCells[4]).toHaveTextContent('')
  })

  it('includes the total number of students in the checkbox label', async () => {
    const mocks = await makeMocks()

    const {findByRole} = render(
      <MockedProvider mocks={mocks} cache={createCache()}>
        <MessageStudentsWhoDialog {...makeProps()} />
      </MockedProvider>
    )
    expect(await findByRole('checkbox', {name: /Students/})).toHaveAccessibleName('4 Students')
  })

  it('includes the total number of observers in the checkbox label', async () => {
    const mocks = await makeMocks()

    const {findByRole} = render(
      <MockedProvider mocks={mocks} addTypename={false}>
        <MessageStudentsWhoDialog {...makeProps()} />
      </MockedProvider>
    )
    expect(await findByRole('checkbox', {name: /Observers/})).toHaveAccessibleName('2 Observers')
  })

  describe('available criteria', () => {
    it('includes score-related options but no "Marked incomplete" option for point-based assignments', async () => {
      const mocks = await makeMocks()

      const {getAllByRole, findByLabelText} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedProvider>
      )
      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      const criteriaLabels = getAllByRole('option').map(option => option.textContent)
      expect(criteriaLabels).toContain('Have not yet submitted')
      expect(criteriaLabels).toContain('Have not been graded')
      expect(criteriaLabels).toContain('Scored more than')
      expect(criteriaLabels).toContain('Scored less than')
      expect(criteriaLabels).not.toContain('Marked incomplete')
    })

    it('includes "Marked incomplete" but no score-related options for pass-fail assignments', async () => {
      const mocks = await makeMocks()

      const {findByLabelText, getAllByRole} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps({assignment: passFailAssignment})} />
        </MockedProvider>
      )
      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      const criteriaLabels = getAllByRole('option').map(option => option.textContent)
      expect(criteriaLabels).toContain('Have not yet submitted')
      expect(criteriaLabels).toContain('Have not been graded')
      expect(criteriaLabels).toContain('Marked incomplete')
      expect(criteriaLabels).not.toContain('Scored more than')
      expect(criteriaLabels).not.toContain('Scored less than')
    })

    it('does not include "Marked incomplete" or score-related options for ungraded assignments', async () => {
      const mocks = await makeMocks()

      const {getAllByRole, findByLabelText} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps({assignment: ungradedAssignment})} />
        </MockedProvider>
      )
      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      const criteriaLabels = getAllByRole('option').map(option => option.textContent)
      expect(criteriaLabels).not.toContain('Marked incomplete')
      expect(criteriaLabels).not.toContain('Scored more than')
      expect(criteriaLabels).not.toContain('Scored less than')
    })

    it('includes "Have not yet submitted" if the assignment accepts digital submissions', async () => {
      const mocks = await makeMocks()

      const {getAllByRole, findByLabelText} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedProvider>
      )
      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      const criteriaLabels = getAllByRole('option').map(option => option.textContent)
      expect(criteriaLabels).toContain('Have not yet submitted')
    })

    it('does not include "Have not yet submitted" if the assignment does not accept digital submissions', async () => {
      const mocks = await makeMocks()

      const {getAllByRole, findByLabelText} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps({assignment: unsubmittableAssignment})} />
        </MockedProvider>
      )
      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      const criteriaLabels = getAllByRole('option').map(option => option.textContent)
      expect(criteriaLabels).not.toContain('Have not yet submitted')
    })

    it('includes "Reassigned" if the assignment has a due date and allows more than one attempt', async () => {
      const mocks = await makeMocks()

      const {getAllByRole, findByLabelText} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedProvider>
      )
      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      const criteriaLabels = getAllByRole('option').map(option => option.textContent)
      expect(criteriaLabels).toContain('Reassigned')
    })

    it('does not include "Reassigned" if the assignment does not have a due date', async () => {
      const mocks = await makeMocks()

      const {getAllByRole, findByLabelText} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps({assignment: passFailAssignment})} />
        </MockedProvider>
      )
      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      const criteriaLabels = getAllByRole('option').map(option => option.textContent)
      expect(criteriaLabels).not.toContain('Reassigned')
    })

    it('does not include "Reassigned" if the assignment does not allow more than one submission', async () => {
      const mocks = await makeMocks()

      const {getAllByRole, findByLabelText} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps({assignment: ungradedAssignment})} />
        </MockedProvider>
      )
      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      const criteriaLabels = getAllByRole('option').map(option => option.textContent)
      expect(criteriaLabels).not.toContain('Reassigned')
    })

    it('does not include "Reassigned" if the assignment is on paper', async () => {
      const mocks = await makeMocks()

      const {getAllByRole, findByLabelText} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps({assignment: unsubmittableAssignment})} />
        </MockedProvider>
      )
      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      const criteriaLabels = getAllByRole('option').map(option => option.textContent)
      expect(criteriaLabels).not.toContain('Reassigned')
    })
  })

  describe('cutoff input', () => {
    it('is shown only when "Scored more than" or "Scored less than" is selected', async () => {
      const mocks = await makeMocks()

      const {getByLabelText, getByRole, queryByLabelText} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedProvider>
      )
      await waitFor(() => {
        expect(queryByLabelText('Enter score cutoff')).not.toBeInTheDocument()
      })

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

  describe('selected criteria', () => {
    beforeEach(() => {
      students.forEach(student => {
        student.submittedAt = undefined
        student.excused = undefined
        student.grade = undefined
        student.score = undefined
      })
    })
    it('updates the student and observer checkbox counts', async () => {
      students[0].grade = '8'
      students[1].grade = '10'
      const mocks = await makeMocks()

      const {findByRole, getByLabelText, getByText} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedProvider>
      )
      expect(await findByRole('checkbox', {name: /Students/})).toHaveAccessibleName('4 Students')
      expect(await findByRole('checkbox', {name: /Observers/})).toHaveAccessibleName('2 Observers')

      const button = getByLabelText(/For students who/)
      fireEvent.click(button)
      fireEvent.click(getByText(/Have not been graded/))

      expect(await findByRole('checkbox', {name: /Students/})).toHaveAccessibleName('2 Students')
      expect(await findByRole('checkbox', {name: /Observers/})).toHaveAccessibleName('0 Observers')
    })

    it('"Have not yet submitted" does not display students who are excused', async () => {
      const mocks = await makeMocks()
      students[2].excused = true
      const {getAllByRole, getByRole, findByLabelText, getByText} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedProvider>
      )

      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      fireEvent.click(getByText(/Have not yet submitted/))

      fireEvent.click(getByRole('button', {name: 'Show all recipients'}))
      expect(getByRole('table')).toBeInTheDocument()

      const tableRows = getAllByRole('row') as HTMLTableRowElement[]
      const studentCells = tableRows.map(row => row.cells[0])
      expect(studentCells).toHaveLength(4)
      expect(studentCells[0]).toHaveTextContent('Students')
      expect(studentCells[1]).toHaveTextContent('Betty Ford')
      expect(studentCells[2]).toHaveTextContent('Adam Jones')
      expect(studentCells[3]).toHaveTextContent('Dana Smith')
    })

    it('"Have not yet submitted" displays students who have no submitted next to their observers', async () => {
      const mocks = await makeMocks()
      students[2].submittedAt = new Date()
      students[3].submittedAt = new Date()
      const {getAllByRole, getByRole, findByLabelText, getByText} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedProvider>
      )

      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      fireEvent.click(getByText(/Have not yet submitted/))

      fireEvent.click(getByRole('button', {name: 'Show all recipients'}))
      expect(getByRole('table')).toBeInTheDocument()

      const tableRows = getAllByRole('row') as HTMLTableRowElement[]
      const studentCells = tableRows.map(row => row.cells[0])
      const observerCells = tableRows.map(row => row.cells[1])
      // first cell will be the header
      expect(studentCells).toHaveLength(3)
      expect(studentCells[0]).toHaveTextContent('Students')
      expect(studentCells[1]).toHaveTextContent('Betty Ford')
      expect(observerCells[1]).toHaveTextContent('Observer0')
      expect(studentCells[2]).toHaveTextContent('Adam Jones')
      expect(observerCells[2]).toHaveTextContent('Observer1')
    })

    it('"Have not been graded" does not display students who are excused', async () => {
      const mocks = await makeMocks()
      students[2].excused = true
      const {getAllByRole, getByRole, findByLabelText, getByText} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedProvider>
      )

      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      fireEvent.click(getByText(/Have not been graded/))

      fireEvent.click(getByRole('button', {name: 'Show all recipients'}))
      expect(getByRole('table')).toBeInTheDocument()

      const tableRows = getAllByRole('row') as HTMLTableRowElement[]
      const studentCells = tableRows.map(row => row.cells[0])
      // first cell will be the header
      expect(studentCells).toHaveLength(4)
      expect(studentCells[0]).toHaveTextContent('Students')
      expect(studentCells[1]).toHaveTextContent('Betty Ford')
      expect(studentCells[2]).toHaveTextContent('Adam Jones')
      expect(studentCells[3]).toHaveTextContent('Dana Smith')
    })

    it('"Have not been graded" displays students who do not have a grade', async () => {
      const mocks = await makeMocks()
      students[0].grade = '8'
      students[1].grade = '10'
      const {getAllByRole, getByRole, findByLabelText, getByText} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedProvider>
      )

      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      fireEvent.click(getByText(/Have not been graded/))

      fireEvent.click(getByRole('button', {name: 'Show all recipients'}))
      expect(getByRole('table')).toBeInTheDocument()

      const tableRows = getAllByRole('row') as HTMLTableRowElement[]
      const studentCells = tableRows.map(row => row.cells[0])
      // first cell will be the header
      expect(studentCells).toHaveLength(3)
      expect(studentCells[0]).toHaveTextContent('Students')
      expect(studentCells[1]).toHaveTextContent('Dana Smith')
      expect(studentCells[2]).toHaveTextContent('Charlie Xi')
    })

    it('"Scored more than" displays students who have scored higher than the score inputted', async () => {
      const mocks = await makeMocks()
      students[0].score = 10
      students[1].score = 5.2
      students[2].score = 4
      students[3].score = 0
      const {getAllByRole, getByRole, getByLabelText, getByText, findByLabelText} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedProvider>
      )

      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      fireEvent.click(getByText(/Scored more than/))
      fireEvent.change(getByLabelText('Enter score cutoff'), {target: {value: '5.1'}})

      fireEvent.click(getByRole('button', {name: 'Show all recipients'}))
      expect(getByRole('table')).toBeInTheDocument()

      const tableRows = getAllByRole('row') as HTMLTableRowElement[]
      const studentCells = tableRows.map(row => row.cells[0])
      const observerCells = tableRows.map(row => row.cells[1])
      // first cell will be the header
      expect(studentCells).toHaveLength(3)
      expect(studentCells[0]).toHaveTextContent('Students')
      expect(studentCells[1]).toHaveTextContent('Betty Ford')
      expect(observerCells[1]).toHaveTextContent('Observer0')
      expect(studentCells[2]).toHaveTextContent('Adam Jones')
      expect(observerCells[2]).toHaveTextContent('Observer1')
    })

    it('"Scored less than" displays students who have scored lower than the score inputted', async () => {
      const mocks = await makeMocks()
      students[0].score = 10
      students[1].score = 6
      students[2].score = 5.2
      students[3].score = 0
      const {getAllByRole, getByRole, findByLabelText, getByLabelText, getByText} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedProvider>
      )

      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      fireEvent.click(getByText(/Scored less than/))
      fireEvent.change(getByLabelText('Enter score cutoff'), {target: {value: '5.1'}})

      fireEvent.click(getByRole('button', {name: 'Show all recipients'}))
      expect(getByRole('table')).toBeInTheDocument()

      const tableRows = getAllByRole('row') as HTMLTableRowElement[]
      const studentCells = tableRows.map(row => row.cells[0])
      // first cell will be the header
      expect(studentCells).toHaveLength(2)
      expect(studentCells[0]).toHaveTextContent('Students')
      expect(studentCells[1]).toHaveTextContent('Dana Smith')
    })

    it('"Total Grade higher than" displays students who have a total grade higher than grade inputed', async () => {
      const mocks = await makeMocks()
      students[0].currentScore = 80
      students[1].currentScore = 50
      students[2].currentScore = 75
      const {getAllByRole, getByRole, findByLabelText, getByLabelText, getByText, getByTestId} =
        render(
          <MockedProvider mocks={mocks} cache={createCache()}>
            <MessageStudentsWhoDialog
              {...makeProps({assignment: null, pointsBasedGradingScheme: false})}
            />
          </MockedProvider>
        )

      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      fireEvent.click(getByText(/Total Grade higher than/))
      fireEvent.change(getByLabelText('Enter score cutoff'), {target: {value: '70'}})

      fireEvent.click(getByTestId('show_all_recipients'))
      expect(getByRole('table')).toBeInTheDocument()

      const tableRows = getAllByRole('row') as HTMLTableRowElement[]
      const studentCells = tableRows.map(row => row.cells[0])
      // first cell with be the header
      expect(studentCells).toHaveLength(3)
      expect(studentCells[0]).toHaveTextContent('Students')
      expect(studentCells[1]).toHaveTextContent('Betty Ford')
      expect(studentCells[2]).toHaveTextContent('Charlie Xi')
    })

    it('"Total Grade lower than" displays students who have a total grade higher than grade inputed', async () => {
      const mocks = await makeMocks()
      students[0].currentScore = 80
      students[1].currentScore = 50
      students[2].currentScore = 75
      const {getAllByRole, getByRole, findByLabelText, getByLabelText, getByText, getByTestId} =
        render(
          <MockedProvider mocks={mocks} cache={createCache()}>
            <MessageStudentsWhoDialog
              {...makeProps({assignment: null, pointsBasedGradingScheme: false})}
            />
          </MockedProvider>
        )

      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      fireEvent.click(getByText(/Total Grade lower than/))
      fireEvent.change(getByLabelText('Enter score cutoff'), {target: {value: '70'}})

      fireEvent.click(getByTestId('show_all_recipients'))
      expect(getByRole('table')).toBeInTheDocument()

      const tableRows = getAllByRole('row') as HTMLTableRowElement[]
      const studentCells = tableRows.map(row => row.cells[0])
      // first cell with be the header
      expect(studentCells).toHaveLength(2)
      expect(studentCells[0]).toHaveTextContent('Students')
      expect(studentCells[1]).toHaveTextContent('Adam Jones')
    })

    it('"Reassigned" displays students who have been asked to resubmit to the assignment', async () => {
      const mocks = await makeMocks()
      students[0].redoRequest = true
      students[1].redoRequest = true
      const {getAllByRole, getByRole, getByText, findByLabelText} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedProvider>
      )

      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      fireEvent.click(getByText(/Reassigned/))

      fireEvent.click(getByRole('button', {name: 'Show all recipients'}))
      expect(getByRole('table')).toBeInTheDocument()

      const tableRows = getAllByRole('row') as HTMLTableRowElement[]
      const studentCells = tableRows.map(row => row.cells[0])
      const observerCells = tableRows.map(row => row.cells[1])
      // first cell will be the header
      expect(studentCells).toHaveLength(3)
      expect(studentCells[0]).toHaveTextContent('Students')
      expect(studentCells[1]).toHaveTextContent('Betty Ford')
      expect(observerCells[1]).toHaveTextContent('Observer0')
      expect(studentCells[2]).toHaveTextContent('Adam Jones')
      expect(observerCells[2]).toHaveTextContent('Observer1')
    })

    it('"Marked incomplete" displays students who have been marked as "incomplete" on a pass/fail assignment', async () => {
      const mocks = await makeMocks()
      students[0].grade = 'incomplete'
      students[1].grade = 'incomplete'
      const {getAllByRole, getByRole, findByLabelText, getByText} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps({assignment: passFailAssignment})} />
        </MockedProvider>
      )

      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      fireEvent.click(getByText(/Marked incomplete/))

      fireEvent.click(getByRole('button', {name: 'Show all recipients'}))
      expect(getByRole('table')).toBeInTheDocument()

      const tableRows = getAllByRole('row') as HTMLTableRowElement[]
      const studentCells = tableRows.map(row => row.cells[0])
      const observerCells = tableRows.map(row => row.cells[1])
      // first cell will be the header
      expect(studentCells).toHaveLength(3)
      expect(studentCells[0]).toHaveTextContent('Students')
      expect(studentCells[0]).toHaveTextContent('Students')
      expect(studentCells[1]).toHaveTextContent('Betty Ford')
      expect(observerCells[1]).toHaveTextContent('Observer0')
      expect(studentCells[2]).toHaveTextContent('Adam Jones')
      expect(observerCells[2]).toHaveTextContent('Observer1')
    })
  })

  describe('default subject', () => {
    it('is set to the first criteria that is listed upon opening the modal', async () => {
      const mocks = await makeMocks()
      const {findByTestId} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedProvider>
      )

      const subjectInput = await findByTestId('subject-input')
      expect(subjectInput).toHaveValue('No submission for A pointed assignment')
    })

    it('is updated when a new criteria is selected', async () => {
      const mocks = await makeMocks()
      const {findByLabelText, getByText, findByTestId} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedProvider>
      )

      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      fireEvent.click(getByText(/Have not been graded/))

      const subjectInput = await findByTestId('subject-input')
      expect(subjectInput).toHaveValue('No grade for A pointed assignment')
    })

    it('is updated to represent the cutoff input when scored more/less than criteria is selected', async () => {
      const mocks = await makeMocks()
      const {findByLabelText, getByText, findByTestId, getByLabelText} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedProvider>
      )

      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      fireEvent.click(getByText(/Scored more than/))

      const subjectInput = await findByTestId('subject-input')
      expect(subjectInput).toHaveValue('Scored more than 0 on A pointed assignment')

      const cutoffInput = await getByLabelText('Enter score cutoff')
      fireEvent.change(cutoffInput, {target: {value: '5'}})

      expect(subjectInput).toHaveValue('Scored more than 5 on A pointed assignment')

      fireEvent.click(button)
      fireEvent.click(getByText(/Scored less than/))

      expect(subjectInput).toHaveValue('Scored less than 5 on A pointed assignment')
    })
  })

  describe('students selection', () => {
    beforeEach(() => {
      students[0].submittedAt = undefined
      students[1].submittedAt = undefined
      students[2].submittedAt = undefined
      students[3].submittedAt = undefined
    })

    it('selects all students by default', async () => {
      const mocks = await makeMocks()
      const {findByRole, getByRole} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedProvider>
      )

      const button = await findByRole('button', {name: 'Show all recipients'})
      fireEvent.click(button)

      const studentCells = students.map(({name}) => getByRole('button', {name}))
      studentCells.forEach(studentCell => expectToBeSelected(studentCell))
    })

    it('sets the students checkbox as checked when all students are selected', async () => {
      const mocks = await makeMocks()
      const {findByRole} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedProvider>
      )

      const button = await findByRole('button', {name: 'Show all recipients'})
      fireEvent.click(button)

      const checkbox = (await findByRole('checkbox', {name: /Students/})) as HTMLInputElement
      await waitFor(() => {
        expect(checkbox.checked).toBe(true)
        expect(checkbox.indeterminate).toBe(false)
        expect(checkbox.disabled).toBe(false)
      })
    })

    it('sets the students checkbox as unchecked when all students are unselected', async () => {
      const mocks = await makeMocks()
      const {findByRole, getByRole} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedProvider>
      )

      const button = await findByRole('button', {name: 'Show all recipients'})
      fireEvent.click(button)

      const checkbox = (await findByRole('checkbox', {name: /Students/})) as HTMLInputElement
      const studentCells = students.map(({name}) => getByRole('button', {name}))
      studentCells.forEach(cell => fireEvent.click(cell))

      await waitFor(() => {
        expect(checkbox.checked).toBe(false)
        expect(checkbox.indeterminate).toBe(false)
        expect(checkbox.disabled).toBe(false)
      })
    })

    it('sets the students checkbox as indeterminate when selected students length is between 1 and the total number of students', async () => {
      const mocks = await makeMocks()

      const {findByRole, getByRole} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedProvider>
      )

      const button = await findByRole('button', {name: 'Show all recipients'})
      fireEvent.click(button)

      const checkbox = (await findByRole('checkbox', {name: /Students/})) as HTMLInputElement
      const studentCells = students.map(({name}) => getByRole('button', {name}))

      fireEvent.click(studentCells[0])

      await waitFor(() => {
        expect(checkbox.checked).toBe(false)
        expect(checkbox.indeterminate).toBe(true)
      })

      fireEvent.click(studentCells[0])
      studentCells.forEach(cell => fireEvent.click(cell))
      fireEvent.click(studentCells[0])

      await waitFor(() => {
        expect(checkbox.checked).toBe(false)
        expect(checkbox.indeterminate).toBe(true)
        expect(checkbox.disabled).toBe(false)
      })
    })

    it('sets the students checkbox as disabled when the students list is empty', async () => {
      const mocks = await makeMocks()

      const {findByRole} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps({students: []})} />
        </MockedProvider>
      )

      const button = await findByRole('button', {name: 'Show all recipients'})
      fireEvent.click(button)

      const checkbox = (await findByRole('checkbox', {name: /Students/})) as HTMLInputElement

      await waitFor(() => {
        expect(checkbox.checked).toBe(false)
        expect(checkbox.indeterminate).toBe(false)
        expect(checkbox.disabled).toBe(true)
      })
    })

    it('unselects a selected student by clicking on the student cell', async () => {
      const mocks = await makeMocks()

      const {findByRole, getByRole} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedProvider>
      )

      const button = await findByRole('button', {name: 'Show all recipients'})
      fireEvent.click(button)

      const studentCells = students.map(({name}) => getByRole('button', {name}))

      fireEvent.click(studentCells[0])
      expectToBeUnselected(studentCells[0])
    })

    it('selects an unselected student by clicking on the student cell', async () => {
      const mocks = await makeMocks()

      const {findByRole, getByRole} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedProvider>
      )

      const button = await findByRole('button', {name: 'Show all recipients'})
      fireEvent.click(button)

      const studentCells = students.map(({name}) => getByRole('button', {name}))

      fireEvent.click(studentCells[0])
      fireEvent.click(studentCells[0])

      expectToBeSelected(studentCells[0])
    })
  })

  describe('observers selection', () => {
    beforeEach(() => {
      students[0].submittedAt = undefined
      students[1].submittedAt = undefined
      students[2].submittedAt = undefined
      students[3].submittedAt = undefined
    })

    it('unselects all observers by default', async () => {
      const mocks = await makeMocks()
      const {findByRole, getByRole} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedProvider>
      )

      const button = await findByRole('button', {name: 'Show all recipients'})
      fireEvent.click(button)

      const observerCells = allObserverNames().map(name => getByRole('button', {name}))
      observerCells.forEach(observerCell => expectToBeUnselected(observerCell))
    })

    it('sets the observers checkbox as checked when all observers are selected', async () => {
      const mocks = await makeMocks()
      const {findByRole, getByRole} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedProvider>
      )

      const button = await findByRole('button', {name: 'Show all recipients'})
      fireEvent.click(button)

      const observerCells = allObserverNames().map(name => getByRole('button', {name}))
      observerCells.forEach(cell => fireEvent.click(cell))

      const checkbox = (await findByRole('checkbox', {name: /Observers/})) as HTMLInputElement
      await waitFor(() => {
        expect(checkbox.checked).toBe(true)
        expect(checkbox.indeterminate).toBe(false)
        expect(checkbox.disabled).toBe(false)
      })
    })

    it('sets the observers checkbox as unchecked when all observers are unselected', async () => {
      const mocks = await makeMocks()
      const {findByRole} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedProvider>
      )

      const button = await findByRole('button', {name: 'Show all recipients'})
      fireEvent.click(button)

      const checkbox = (await findByRole('checkbox', {name: /Observers/})) as HTMLInputElement

      await waitFor(() => {
        expect(checkbox.checked).toBe(false)
        expect(checkbox.indeterminate).toBe(false)
        expect(checkbox.disabled).toBe(false)
      })
    })

    it('sets the observers checkbox as indeterminate when selected students length is between 1 and the total number of students', async () => {
      const mocks = await makeMocks()

      const {findByRole, getByRole} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedProvider>
      )

      const button = await findByRole('button', {name: 'Show all recipients'})
      fireEvent.click(button)

      const checkbox = (await findByRole('checkbox', {name: /Observers/})) as HTMLInputElement
      const observerCells = allObserverNames().map(name => getByRole('button', {name}))

      fireEvent.click(observerCells[0])

      await waitFor(() => {
        expect(checkbox.checked).toBe(false)
        expect(checkbox.indeterminate).toBe(true)
      })

      fireEvent.click(observerCells[0])
      observerCells.forEach(cell => fireEvent.click(cell))
      fireEvent.click(observerCells[0])

      await waitFor(() => {
        expect(checkbox.checked).toBe(false)
        expect(checkbox.indeterminate).toBe(true)
        expect(checkbox.disabled).toBe(false)
      })
    })

    it('sets the observers checkbox as disabled when the observer list is empty', async () => {
      const mocks = await makeMocks()
      const newStudent = {
        id: '104',
        name: 'Charlie Brown',
        grade: undefined,
        redoRequest: false,
        sortableName: 'Charlie, Brown',
        score: undefined,
        submittedAt: undefined,
      }
      const {findByRole} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps({students: [newStudent]})} />
        </MockedProvider>
      )

      const button = await findByRole('button', {name: 'Show all recipients'})
      fireEvent.click(button)

      const checkbox = (await findByRole('checkbox', {name: /Observers/})) as HTMLInputElement

      await waitFor(() => {
        expect(checkbox.checked).toBe(false)
        expect(checkbox.indeterminate).toBe(false)
        expect(checkbox.disabled).toBe(true)
      })
    })

    it('unselects a selected observer by clicking on the observer cell', async () => {
      const mocks = await makeMocks()

      const {findByRole, getByRole} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedProvider>
      )

      const button = await findByRole('button', {name: 'Show all recipients'})
      fireEvent.click(button)

      const observerCells = allObserverNames().map(name => getByRole('button', {name}))

      expectToBeUnselected(observerCells[0])
    })

    it('selects an unselected observer by clicking on the observer cell', async () => {
      const mocks = await makeMocks()

      const {findByRole, getByRole} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedProvider>
      )

      const button = await findByRole('button', {name: 'Show all recipients'})
      fireEvent.click(button)

      const observerCells = allObserverNames().map(name => getByRole('button', {name}))

      fireEvent.click(observerCells[0])
      expectToBeSelected(observerCells[0])
    })
  })

  describe('send message button', () => {
    it('is disabled when the message body is empty', async () => {
      const mocks = await makeMocks()

      const {findByRole, getByTestId} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedProvider>
      )

      const recipientsButton = await findByRole('button', {name: 'Show all recipients'})
      fireEvent.click(recipientsButton)

      const messageTextArea = getByTestId('message-input')
      fireEvent.change(messageTextArea, {target: {value: ''}})

      const sendButton = await findByRole('button', {name: 'Send'})
      expect(sendButton).toBeDisabled()
    })

    it('is disabled when the message body has only whitespaces', async () => {
      const mocks = await makeMocks()

      const {findByRole, getByTestId} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedProvider>
      )

      const recipientsButton = await findByRole('button', {name: 'Show all recipients'})
      fireEvent.click(recipientsButton)

      const messageTextArea = getByTestId('message-input')
      fireEvent.change(messageTextArea, {target: {value: '   '}})

      const sendButton = await findByRole('button', {name: 'Send'})
      expect(sendButton).toBeDisabled()
    })

    it('is disabled when there are no students/observers selected', async () => {
      const mocks = await makeMocks()

      const {findByRole} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedProvider>
      )

      const recipientsButton = await findByRole('button', {name: 'Show all recipients'})
      const checkbox = (await findByRole('checkbox', {name: /Students/})) as HTMLInputElement

      fireEvent.click(recipientsButton)
      fireEvent.click(checkbox)

      const sendButton = await findByRole('button', {name: 'Send'})
      expect(sendButton).toBeDisabled()
    })

    it('is enabled when the message body is not empty and there is at least one student/observer selected', async () => {
      const mocks = await makeMocks()

      const {findByRole, getByTestId} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedProvider>
      )

      const recipientsButton = await findByRole('button', {name: 'Show all recipients'})
      fireEvent.click(recipientsButton)

      const messageTextArea = getByTestId('message-input')
      fireEvent.change(messageTextArea, {target: {value: 'FOO BAR'}})

      const sendButton = await findByRole('button', {name: 'Send'})
      expect(sendButton).not.toBeDisabled()
    })
  })

  describe('onSend', () => {
    let onClose: jest.Mock<any, any>
    let onSend: jest.Mock<any, any>

    beforeEach(() => {
      onClose = jest.fn()
      onSend = jest.fn()
    })

    it('is called with the specified subject', async () => {
      const mocks = await makeMocks()

      const {findByRole, getByTestId} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps({onClose, onSend})} />
        </MockedProvider>
      )

      const recipientsButton = await findByRole('button', {name: 'Show all recipients'})
      fireEvent.click(recipientsButton)

      const subjectInput = getByTestId('subject-input')
      fireEvent.change(subjectInput, {target: {value: 'SUBJECT'}})

      const messageTextArea = getByTestId('message-input')
      fireEvent.change(messageTextArea, {target: {value: 'BODY'}})

      const sendButton = await findByRole('button', {name: 'Send'})
      fireEvent.click(sendButton)

      expect(onSend).toHaveBeenCalledWith(expect.objectContaining({subject: 'SUBJECT'}))
      expect(onClose).toHaveBeenCalled()
    })

    it('is called with the specified body', async () => {
      const mocks = await makeMocks()

      const {findByRole, getByTestId} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps({onClose, onSend})} />
        </MockedProvider>
      )

      const recipientsButton = await findByRole('button', {name: 'Show all recipients'})
      fireEvent.click(recipientsButton)

      const subjectInput = getByTestId('subject-input')
      fireEvent.change(subjectInput, {target: {value: 'SUBJECT'}})

      const messageTextArea = getByTestId('message-input')
      fireEvent.change(messageTextArea, {target: {value: 'BODY'}})

      const sendButton = await findByRole('button', {name: 'Send'})
      fireEvent.click(sendButton)

      expect(onSend).toHaveBeenCalledWith(expect.objectContaining({body: 'BODY'}))
      expect(onClose).toHaveBeenCalled()
    })

    it('is called with the selected students', async () => {
      const mocks = await makeMocks()

      const {findByRole, getByRole, getByTestId} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps({onClose, onSend})} />
        </MockedProvider>
      )

      const recipientsButton = await findByRole('button', {name: 'Show all recipients'})
      fireEvent.click(recipientsButton)

      const studentCells = students.map(({name}) => getByRole('button', {name}))
      fireEvent.click(studentCells[0])

      const subjectInput = getByTestId('subject-input')
      fireEvent.change(subjectInput, {target: {value: 'SUBJECT'}})

      const messageTextArea = getByTestId('message-input')
      fireEvent.change(messageTextArea, {target: {value: 'BODY'}})

      const sendButton = await findByRole('button', {name: 'Send'})
      fireEvent.click(sendButton)

      expect(onSend).toHaveBeenCalledWith(
        expect.objectContaining({recipientsIds: ['101', '102', '103']})
      )
      expect(onClose).toHaveBeenCalled()
    })

    it('is called with the selected observers', async () => {
      const mocks = await makeMocks()

      const {findByRole, getByRole, getByTestId} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps({onClose, onSend})} />
        </MockedProvider>
      )

      const recipientsButton = await findByRole('button', {name: 'Show all recipients'})
      fireEvent.click(recipientsButton)

      const checkbox = (await findByRole('checkbox', {name: /Students/})) as HTMLInputElement
      fireEvent.click(checkbox)

      const observerCells = allObserverNames().map(name => getByRole('button', {name}))
      fireEvent.click(observerCells[0])
      fireEvent.click(observerCells[1])

      const subjectInput = getByTestId('subject-input')
      fireEvent.change(subjectInput, {target: {value: 'SUBJECT'}})

      const messageTextArea = getByTestId('message-input')
      fireEvent.change(messageTextArea, {target: {value: 'BODY'}})

      const sendButton = await findByRole('button', {name: 'Send'})
      fireEvent.click(sendButton)

      const observerIds = mocks[0].result.data?.course.enrollmentsConnection.nodes.map(
        node => node.user._id
      )
      expect(onSend).toHaveBeenCalledWith(expect.objectContaining({recipientsIds: observerIds}))
      expect(onClose).toHaveBeenCalled()
    })
  })
})
