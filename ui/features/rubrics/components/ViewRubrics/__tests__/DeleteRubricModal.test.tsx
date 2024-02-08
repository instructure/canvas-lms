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
import Router from 'react-router'
import {BrowserRouter} from 'react-router-dom'
import {render, waitFor} from '@testing-library/react'
import {QueryProvider} from '@canvas/query'
import {DeleteRubricModal} from '../DeleteRubricModal'
import * as ViewRubricQueries from '../../../queries/ViewRubricQueries'

jest.mock('react-router', () => ({
  ...jest.requireActual('react-router'),
  useParams: jest.fn(),
}))
const onDismiss = jest.fn()
const setPopoverIsOpen = jest.fn()
const deleteRubricMock = jest.fn()
jest.mock('../../../queries/ViewRubricQueries', () => ({
  ...jest.requireActual('../../../queries/ViewRubricQueries'),
  deleteRubric: () => deleteRubricMock,
}))

describe('RubricForm Tests', () => {
  beforeEach(() => {
    jest.spyOn(Router, 'useParams').mockReturnValue({accountId: '1', rubricId: '1'})
  })
  afterEach(() => {
    jest.resetAllMocks()
  })

  const renderComponent = (isOpen = true) => {
    return render(
      <QueryProvider>
        <BrowserRouter>
          <DeleteRubricModal
            id="1"
            title="test rubric"
            isOpen={isOpen}
            onDismiss={onDismiss}
            setPopoverIsOpen={setPopoverIsOpen}
          />
        </BrowserRouter>
      </QueryProvider>
    )
  }

  const getSRAlert = () => document.querySelector('#flash_screenreader_holder')?.textContent

  it('renders the DeleteRubricModal component', () => {
    const {getByText} = renderComponent()
    expect(getByText('Delete test rubric')).toBeInTheDocument()
  })

  it('closes the modal when the close button is clicked', async () => {
    const {getByTestId} = renderComponent()
    const closeButtonContainer = getByTestId('close-delete-rubric-modal-button')
    const closeButton = closeButtonContainer.querySelector('button')
    closeButton?.click()
    await waitFor(() => {
      expect(onDismiss).toHaveBeenCalled()
    })
  })

  it('closes the modal when the cancel button is clicked', async () => {
    const {getByTestId} = renderComponent()
    const cancelButton = getByTestId('cancel-delete-rubric-modal-button')
    cancelButton?.click()
    await waitFor(() => {
      expect(onDismiss).toHaveBeenCalled()
    })
  })

  it('deletes the rubric when the delete button is clicked', async () => {
    jest
      .spyOn(ViewRubricQueries, 'deleteRubric')
      .mockImplementation(() => Promise.resolve({id: '1', title: 'Rubric 1', pointsPossible: 10}))
    const {getByTestId} = renderComponent()
    const deleteButton = getByTestId('delete-rubric-button')
    deleteButton?.click()
    await new Promise(resolve => setTimeout(resolve, 0))
    expect(getSRAlert()).toEqual('Rubric deleted successfully')
  })
})
