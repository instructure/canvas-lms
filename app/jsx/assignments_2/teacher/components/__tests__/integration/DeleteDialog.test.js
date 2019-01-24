/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {fireEvent, wait, waitForElement} from 'react-testing-library'
import {mockAssignment, waitForNoElement} from '../../../test-utils'
import {renderTeacherView} from './integration-utils'
import {setWorkflow} from '../../../api'

jest.mock('jsx/shared/rce/RichContentEditor') // jest cannot deal with jquery as loded from here
jest.mock('../../../api')

async function openDeleteDialog(assignment = mockAssignment()) {
  const fns = await renderTeacherView(assignment)
  const openDeleteButton = await waitForElement(() => fns.getByText('delete assignment'))
  fireEvent.click(openDeleteButton)
  return fns
}

afterEach(() => {
  jest.restoreAllMocks()
})

/* eslint-disable jest/no-disabled-tests */
it.skip('allows close', async () => {
  const {getByTestId} = await openDeleteDialog()
  const closeButton = await waitForElement(() => getByTestId('confirm-dialog-close-button'))
  fireEvent.click(closeButton)
  await waitForNoElement(() => getByTestId('confirm-dialog-close-button'))
  expect(setWorkflow).not.toHaveBeenCalled()
})

it.skip('allows cancel', async () => {
  const {getByTestId} = await openDeleteDialog()
  const cancelButton = await waitForElement(() => getByTestId('confirm-dialog-cancel-button'))
  fireEvent.click(cancelButton)
  await waitForNoElement(() => getByTestId('confirm-dialog-cancel-button'))
  expect(setWorkflow).not.toHaveBeenCalled()
})

it.skip('deletes the assignment and reloads', async () => {
  const reloadSpy = jest.spyOn(window.location, 'reload')
  setWorkflow.mockReturnValueOnce({data: {}})
  const assignment = mockAssignment()
  const {getByText, getByTestId} = await openDeleteDialog(assignment)
  const reallyDeleteButton = await waitForElement(() =>
    getByTestId('confirm-dialog-confirm-button')
  )
  fireEvent.click(reallyDeleteButton)
  await waitForElement(() => getByText('deleting assignment')) // the spinner
  await wait(() => expect(setWorkflow).toHaveBeenCalledWith(assignment, 'deleted'))
  expect(reloadSpy).toHaveBeenCalled()
})

// errors aren't really implemented yet
it.skip('reports errors', async () => {
  setWorkflow.mockReturnValueOnce({
    errors: [
      /* errors data structures go here */
    ]
  })
  const {getByTestId} = await openDeleteDialog()
  const reallyDeleteButton = await waitForElement(() =>
    getByTestId('confirm-dialog-confirm-button')
  )
  fireEvent.click(reallyDeleteButton)
  // waitForElement(() => {getBySomething('some kind of error message alert')})
})
/* eslint-enable jest/no-disabled-tests */
