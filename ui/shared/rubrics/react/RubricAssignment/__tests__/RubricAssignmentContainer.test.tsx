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
import {fireEvent, render} from '@testing-library/react'
import {
  RubricAssignmentContainer,
  type RubricAssignmentContainerProps,
} from '../components/RubricAssignmentContainer'
import * as RubricFormQueries from '@canvas/rubrics/react/RubricForm/queries/RubricFormQueries'
import {RUBRIC, RUBRIC_ASSOCIATION} from './fixtures'

jest.mock('@canvas/rubrics/react/RubricForm/queries/RubricFormQueries', () => ({
  ...jest.requireActual('@canvas/rubrics/react/RubricForm/queries/RubricFormQueries'),
  saveRubric: jest.fn(),
}))

jest.mock('../queries', () => ({
  ...jest.requireActual('../queries'),
  removeRubricFromAssignment: jest.fn(),
}))

describe('RubricAssignmentContainer Tests', () => {
  beforeEach(() => {
    jest.spyOn(RubricFormQueries, 'saveRubric').mockImplementation(() =>
      Promise.resolve({
        rubric: RUBRIC,
        rubricAssociation: RUBRIC_ASSOCIATION,
      })
    )
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  const renderComponent = (props?: RubricAssignmentContainerProps) => {
    return render(<RubricAssignmentContainer {...props} />)
  }

  describe('non associated rubric', () => {
    it('should render the create and search buttons', () => {
      const {getByText} = renderComponent()
      expect(getByText('Create Rubric')).toBeInTheDocument()
      expect(getByText('Find Rubric')).toBeInTheDocument()
    })

    it('should render the create modal when the create button is clicked', () => {
      const {getByText, getByTestId} = renderComponent()
      getByText('Create Rubric').click()
      expect(getByTestId('rubric-assignment-create-modal')).toHaveTextContent('Create Rubric')
      expect(getByTestId('save-rubric-button')).toBeDisabled()
    })

    it('should save a new rubric and display the Rubric title, edit, preview, and remove buttons', async () => {
      const {getByText, getByTestId} = renderComponent()
      getByText('Create Rubric').click()
      const titleInput = getByTestId('rubric-form-title')
      fireEvent.change(titleInput, {target: {value: 'Rubric 1'}})
      fireEvent.click(getByTestId('add-criterion-button'))

      await new Promise(resolve => setTimeout(resolve, 0))
      expect(getByTestId('rubric-criterion-modal')).toBeInTheDocument()
      fireEvent.change(getByTestId('rubric-criterion-name-input'), {
        target: {value: 'New Criterion Test'},
      })
      fireEvent.click(getByTestId('rubric-criterion-save'))
      fireEvent.click(getByTestId('save-rubric-button'))

      await new Promise(resolve => setTimeout(resolve, 0))
      expect(document.querySelector('#flash_screenreader_holder')?.textContent).toEqual(
        'Rubric saved successfully'
      )
      expect(getByTestId('preview-assignment-rubric-button')).toBeInTheDocument()
      expect(getByTestId('edit-assignment-rubric-button')).toBeInTheDocument()
      expect(getByTestId('remove-assignment-rubric-button')).toBeInTheDocument()
    })
  })

  describe('associated rubric', () => {
    it('will render the rubric title, edit, preview, and remove buttons when rubric is attached to assignment', () => {
      const {getByTestId} = renderComponent({
        assignmentRubric: RUBRIC,
        assignmentRubricAssociation: RUBRIC_ASSOCIATION,
      })
      expect(getByTestId('preview-assignment-rubric-button')).toBeInTheDocument()
      expect(getByTestId('edit-assignment-rubric-button')).toBeInTheDocument()
      expect(getByTestId('remove-assignment-rubric-button')).toBeInTheDocument()
    })

    it('should render the create modal when the edit button is clicked', () => {
      const {getByTestId} = renderComponent({
        assignmentRubric: RUBRIC,
        assignmentRubricAssociation: RUBRIC_ASSOCIATION,
      })
      fireEvent.click(getByTestId('edit-assignment-rubric-button'))
      expect(getByTestId('rubric-assignment-create-modal')).toHaveTextContent('Edit Rubric')
      expect(getByTestId('rubric-form-title')).toHaveValue('Rubric 1')
    })

    it('should remove the rubric from the assignment when the remove button is clicked', async () => {
      const {getByTestId} = renderComponent({
        assignmentRubric: RUBRIC,
        assignmentRubricAssociation: RUBRIC_ASSOCIATION,
      })
      fireEvent.click(getByTestId('remove-assignment-rubric-button'))
      await new Promise(resolve => setTimeout(resolve, 0))
      expect(getByTestId('create-assignment-rubric-button')).toBeInTheDocument()
      expect(getByTestId('find-assignment-rubric-button')).toBeInTheDocument()
    })

    it('should open the preview tray when the preview button is clicked', async () => {
      const {getByTestId} = renderComponent({
        assignmentRubric: RUBRIC,
        assignmentRubricAssociation: RUBRIC_ASSOCIATION,
      })
      fireEvent.click(getByTestId('preview-assignment-rubric-button'))
      const rubricTray = document.querySelector(
        '[role="dialog"][aria-label="Rubric Assessment Tray"]'
      )
      expect(rubricTray).toBeInTheDocument()
      expect(getByTestId('traditional-criterion-1-ratings-0')).toBeInTheDocument()
      expect(getByTestId('traditional-criterion-1-ratings-1')).toBeInTheDocument()
    })
  })
})
