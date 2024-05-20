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
import {defaultOutcomes, defaultSortableStudents, makeContentSelectionProps} from './fixtures'
import userEvent from '@testing-library/user-event'

describe('Content Selection', () => {
  describe('student dropdown', () => {
    it('displays the sortableName in the student dropdown', () => {
      const props = makeContentSelectionProps({
        students: defaultSortableStudents,
        outcomes: defaultOutcomes,
      })
      const {getByTestId} = render(
        <MockedProvider>
          <ContentSelection {...props} />
        </MockedProvider>
      )
      const studentDropdown = getByTestId('learning-mastery-content-selection-student-select')
      expect(studentDropdown).toHaveTextContent('Last, First')
      expect(studentDropdown).toHaveTextContent('Last2, First2')
    })

    it('moves the focus to the previous student button when the last listed student is selected', async () => {
      const props = makeContentSelectionProps({
        students: defaultSortableStudents,
        outcomes: defaultOutcomes,
      })
      const {getByTestId} = render(
        <MockedProvider>
          <ContentSelection {...props} />
        </MockedProvider>
      )

      const nextStudentButton = getByTestId('learning-mastery-next-student-button')
      expect(nextStudentButton).toBeInTheDocument()

      const previousStudentButton = getByTestId('learning-mastery-previous-student-button')
      expect(previousStudentButton).toBeInTheDocument()

      await userEvent.click(nextStudentButton)
      await userEvent.click(nextStudentButton)
      await userEvent.click(nextStudentButton)

      expect(nextStudentButton).toBeDisabled()
      expect(previousStudentButton).toHaveFocus()
    })

    it('moves the focus to the next student button when the first listed student is selected', async () => {
      const props = makeContentSelectionProps({
        students: defaultSortableStudents,
        outcomes: defaultOutcomes,
      })
      const {getByTestId} = render(
        <MockedProvider>
          <ContentSelection {...props} />
        </MockedProvider>
      )

      const nextStudentButton = getByTestId('learning-mastery-next-student-button')
      expect(nextStudentButton).toBeInTheDocument()

      const previousStudentButton = getByTestId('learning-mastery-previous-student-button')
      expect(previousStudentButton).toBeInTheDocument()

      await userEvent.click(nextStudentButton)
      await userEvent.click(previousStudentButton)

      expect(previousStudentButton).toBeDisabled()
      expect(nextStudentButton).toHaveFocus()
    })

    it('moves the focus to the previous outcome button when the last listed outcome is selected', async () => {
      const props = makeContentSelectionProps({
        students: defaultSortableStudents,
        outcomes: defaultOutcomes,
      })
      const {getByTestId} = render(
        <MockedProvider>
          <ContentSelection {...props} />
        </MockedProvider>
      )

      const nextOutcomeButton = getByTestId('learning-mastery-next-outcome-button')
      expect(nextOutcomeButton).toBeInTheDocument()

      const previousOutcomeButton = getByTestId('learning-mastery-previous-outcome-button')
      expect(previousOutcomeButton).toBeInTheDocument()

      await userEvent.click(nextOutcomeButton)
      await userEvent.click(nextOutcomeButton)

      expect(nextOutcomeButton).toBeDisabled()
      expect(previousOutcomeButton).toHaveFocus()
    })

    it('moves the focus to the next outcome button when the first listed outcome is selected', async () => {
      const props = makeContentSelectionProps({
        students: defaultSortableStudents,
        outcomes: defaultOutcomes,
      })
      const {getByTestId} = render(
        <MockedProvider>
          <ContentSelection {...props} />
        </MockedProvider>
      )

      const nextOutcomeButton = getByTestId('learning-mastery-next-outcome-button')
      expect(nextOutcomeButton).toBeInTheDocument()

      const previousOutcomeButton = getByTestId('learning-mastery-previous-outcome-button')
      expect(previousOutcomeButton).toBeInTheDocument()

      await userEvent.click(nextOutcomeButton)
      await userEvent.click(previousOutcomeButton)

      expect(previousOutcomeButton).toBeDisabled()
      expect(nextOutcomeButton).toHaveFocus()
    })
  })
})
