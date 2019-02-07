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
import {mockAssignment, waitForNoElement, workflowMutationResult} from '../../../test-utils'
import {renderTeacherView} from './integration-utils'

async function openDeleteDialog(assignment = mockAssignment(), apolloMocks = []) {
  const fns = await renderTeacherView(assignment, apolloMocks)
  const openDeleteButton = await waitForElement(() => fns.getByText('delete assignment'))
  fireEvent.click(openDeleteButton)
  return fns
}

afterEach(() => {
  jest.restoreAllMocks()
})

describe('assignments 2 delete dialog', () => {
  it('allows close', async () => {
    const {getByTestId} = await openDeleteDialog()
    const closeButton = await waitForElement(() => getByTestId('confirm-dialog-close-button'))
    fireEvent.click(closeButton)
    expect(await waitForNoElement(() => getByTestId('confirm-dialog-close-button'))).toBe(true)
  })

  it('allows cancel', async () => {
    const {getByTestId} = await openDeleteDialog()
    const cancelButton = await waitForElement(() => getByTestId('confirm-dialog-cancel-button'))
    fireEvent.click(cancelButton)
    expect(await waitForNoElement(() => getByTestId('confirm-dialog-cancel-button'))).toBe(true)
  })

  it('deletes the assignment and reloads', async () => {
    const reloadSpy = jest.spyOn(window.location, 'reload')
    const assignment = mockAssignment()
    const {getByTestId} = await openDeleteDialog(assignment, [
      workflowMutationResult(assignment, 'deleted')
    ])
    const reallyDeleteButton = await waitForElement(() =>
      getByTestId('confirm-dialog-confirm-button')
    )
    fireEvent.click(reallyDeleteButton)
    await wait(() => expect(reloadSpy).toHaveBeenCalled())
  })

  /* eslint-disable jest/no-disabled-tests */
  // errors aren't really implemented yet
  it.skip('reports errors', async () => {
    const assignment = mockAssignment()
    const {getByTestId} = await openDeleteDialog(assignment, [
      // mutation result with an error
    ])
    const reallyDeleteButton = await waitForElement(() =>
      getByTestId('confirm-dialog-confirm-button')
    )
    fireEvent.click(reallyDeleteButton)
    // await waitForElement(() => {getBySomething('some kind of error message alert')})
  })
  /* eslint-enable jest/no-disabled-tests */
})
