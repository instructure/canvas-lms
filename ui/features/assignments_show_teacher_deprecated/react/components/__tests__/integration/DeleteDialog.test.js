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

import {fireEvent, waitFor} from '@testing-library/react'
import {mockAssignment, itBehavesLikeADialog, saveAssignmentResult} from '../../../test-utils'
import {renderTeacherView} from './integration-utils'

async function openDeleteDialog(assignment = mockAssignment(), apolloMocks = []) {
  const fns = await renderTeacherView(assignment, apolloMocks)
  const openDeleteButton = await waitFor(() => fns.getByText('delete assignment'))
  fireEvent.click(openDeleteButton)
  return fns
}

afterEach(() => {
  jest.restoreAllMocks()
})

describe('assignments 2 delete dialog', () => {
  itBehavesLikeADialog({
    render: renderTeacherView,
    getOpenDialogElt: fns => fns.getByText('delete assignment'),
    confirmDialogOpen: fns => fns.getByText(/are you sure/i, {exact: false}),
    getCancelDialogElt: fns => fns.getByTestId('delete-dialog-cancel-button'),
  })

  it.skip('deletes the assignment and reloads', async () => {
    delete window.location
    window.location = {reload: jest.fn()}

    const assignment = mockAssignment()
    const {getByTestId} = await openDeleteDialog(assignment, [
      saveAssignmentResult(assignment, {state: 'deleted'}, {state: 'deleted'}),
    ])
    const reallyDeleteButton = await waitFor(() => getByTestId('delete-dialog-confirm-button'))
    fireEvent.click(reallyDeleteButton)
    await waitFor(() => expect(window.location.reload).toHaveBeenCalled())
  })

  it.skip('reports errors', async () => {
    const assignment = mockAssignment()
    const {getByTestId, getAllByText} = await openDeleteDialog(assignment, [
      saveAssignmentResult(assignment, {state: 'deleted'}, {state: 'deleted'}, 'well rats'),
    ])
    const reallyDeleteButton = await waitFor(() => getByTestId('delete-dialog-confirm-button'))
    fireEvent.click(reallyDeleteButton)
    expect(await waitFor(() => getAllByText(/unable to delete/i)[0])).toBeInTheDocument()
  })
})
