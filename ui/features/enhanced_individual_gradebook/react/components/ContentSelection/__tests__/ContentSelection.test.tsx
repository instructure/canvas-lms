/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {MockedProvider} from '@apollo/react-testing'
import {render} from '@testing-library/react'
import ContentSelection from '..'
import {
  defaultSortableAssignments,
  defaultSortableStudents,
  makeContentSelectionProps,
} from './fixtures'
import userEvent from '@testing-library/user-event'

describe('Content Selection', () => {
  describe('student dropdown', () => {
    it('displays the sortableName in the student dropdown', () => {
      const props = makeContentSelectionProps({students: defaultSortableStudents})
      const {getByTestId} = render(
        <MockedProvider>
          <ContentSelection {...props} />
        </MockedProvider>
      )
      const studentDropdown = getByTestId('content-selection-student-select')
      expect(studentDropdown).toHaveTextContent('Last, First')
      expect(studentDropdown).toHaveTextContent('Last2, First2')
    })

    it('moves the focus to the previous student button when the last listed student is selected', async () => {
      const props = makeContentSelectionProps({
        students: defaultSortableStudents,
        assignments: defaultSortableAssignments,
      })
      const {getByTestId} = render(
        <MockedProvider>
          <ContentSelection {...props} />
        </MockedProvider>
      )
      await userEvent.click(getByTestId('next-student-button'))
      await userEvent.click(getByTestId('next-student-button'))
      await userEvent.click(getByTestId('next-student-button'))
      expect(getByTestId('next-student-button')).toBeDisabled()
      expect(getByTestId('previous-student-button')).toHaveFocus()
    })

    it('moves the focus to the next student button when the first listed student is selected', async () => {
      const props = makeContentSelectionProps({
        students: defaultSortableStudents,
        assignments: defaultSortableAssignments,
      })
      const {getByTestId} = render(
        <MockedProvider>
          <ContentSelection {...props} />
        </MockedProvider>
      )
      await userEvent.click(getByTestId('next-student-button'))
      await userEvent.click(getByTestId('previous-student-button'))
      expect(getByTestId('previous-student-button')).toBeDisabled()
      expect(getByTestId('next-student-button')).toHaveFocus()
    })

    it('moves the focus to the previous assignment button when the last listed assignment is selected', async () => {
      const props = makeContentSelectionProps({
        students: defaultSortableStudents,
        assignments: defaultSortableAssignments,
      })
      const {getByTestId} = render(
        <MockedProvider>
          <ContentSelection {...props} />
        </MockedProvider>
      )
      await userEvent.click(getByTestId('next-assignment-button'))
      await userEvent.click(getByTestId('next-assignment-button'))
      await userEvent.click(getByTestId('next-assignment-button'))
      expect(getByTestId('next-assignment-button')).toBeDisabled()
      expect(getByTestId('previous-assignment-button')).toHaveFocus()
    })

    it('moves the focus to the next assignment button when the first listed assignment is selected', async () => {
      const props = makeContentSelectionProps({
        students: defaultSortableStudents,
        assignments: defaultSortableAssignments,
      })
      const {getByTestId} = render(
        <MockedProvider>
          <ContentSelection {...props} />
        </MockedProvider>
      )
      await userEvent.click(getByTestId('next-assignment-button'))
      await userEvent.click(getByTestId('previous-assignment-button'))
      expect(getByTestId('previous-assignment-button')).toBeDisabled()
      expect(getByTestId('next-assignment-button')).toHaveFocus()
    })
  })
  describe('assignment dropdown', () => {
    it('displays assigned anonymous assignments when no student is selected', () => {
      defaultSortableAssignments[0].anonymizeStudents = true
      const props = makeContentSelectionProps({
        students: defaultSortableStudents,
        selectedStudentId: null,
        assignments: defaultSortableAssignments,
      })
      const {getByTestId} = render(
        <MockedProvider>
          <ContentSelection {...props} />
        </MockedProvider>
      )
      const assignmentDropdown = getByTestId('content-selection-assignment-select')
      expect(assignmentDropdown).toHaveTextContent('Assignment 1')
    })
    it('does not display assigned anonymous assignments when a student is selected', () => {
      defaultSortableAssignments[0].anonymizeStudents = true
      const props = makeContentSelectionProps({
        students: defaultSortableStudents,
        selectedStudentId: '1',
        assignments: defaultSortableAssignments,
      })
      const {getByTestId} = render(
        <MockedProvider>
          <ContentSelection {...props} />
        </MockedProvider>
      )
      const assignmentDropdown = getByTestId('content-selection-assignment-select')
      expect(assignmentDropdown).not.toHaveTextContent('Assignment 1')
    })
  })
})
