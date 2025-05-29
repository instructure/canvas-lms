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
import CreateFolderModal from '../CreateFolderModal'
import {fireEvent, render, screen, within, waitFor} from '@testing-library/react'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {queryClient} from '@canvas/query'
import fetchMock from 'fetch-mock'
import userEvent from '@testing-library/user-event'
import {FileManagementProvider} from '../../../contexts/FileManagementContext'
import {createMockFileManagementContext} from '../../../__tests__/createMockContext'
import fakeENV from '@canvas/test-utils/fakeENV'

const defaultProps = {
  isOpen: true,
  onRequestClose: jest.fn(),
  onExited: jest.fn(),
}

const renderComponent = (props = {}) => {
  return render(
    <FileManagementProvider value={createMockFileManagementContext()}>
      <MockedQueryClientProvider client={queryClient}>
        <CreateFolderModal {...defaultProps} {...props} />
      </MockedQueryClientProvider>
    </FileManagementProvider>,
  )
}
describe('CreateFolderModal', () => {
  beforeEach(() => {
    fakeENV.setup()
    jest.clearAllMocks()
    fetchMock.reset()
    fetchMock.post(/.*\/folders/, 200)
  })

  afterEach(() => {
    fetchMock.reset()
    fetchMock.restore()
    fakeENV.teardown()
  })

  it('closes when Cancel is clicked', async () => {
    const user = userEvent.setup()
    renderComponent()
    const cancelButton = screen.getByRole('button', {name: /cancel/i})
    await user.click(cancelButton)
    expect(defaultProps.onRequestClose).toHaveBeenCalled()
  })

  it('closes when Close Button is clicked', async () => {
    const user = userEvent.setup()
    renderComponent()
    const dialog = screen.getByRole('dialog', {name: 'Create Folder'})
    const closeButton = within(dialog).getByRole('button', {name: /close/i})
    await user.click(closeButton)
    expect(defaultProps.onRequestClose).toHaveBeenCalled()
  })

  it('submits when Create Folder button is clicked', async () => {
    const user = userEvent.setup()
    renderComponent()
    const createFolderButton = screen.getByRole('button', {name: /Create Folder/i})
    await user.click(createFolderButton)

    await waitFor(() => {
      expect(fetchMock.lastCall()?.[1]?.body).toEqual('{"name":""}')
    })
  })

  it('submits on enter', async () => {
    renderComponent()
    const input = screen.getByRole('textbox', {name: /Folder Name/i})
    await userEvent.click(input)
    await userEvent.type(input, '{Enter}')

    await waitFor(() => {
      expect(fetchMock.lastCall()?.[1]?.body).toEqual('{"name":""}')
    })
  })

  it('displays loading spinner when submitting', async () => {
    const user = userEvent.setup()
    // Use a never-resolving promise to keep the loading state active
    fetchMock.post(/.*\/folders/, new Promise(() => {}), {overwriteRoutes: true})
    renderComponent()
    const createFolderButton = screen.getByRole('button', {name: /Create Folder/i})
    await user.click(createFolderButton)

    // Verify the spinner is shown
    expect(screen.getByTestId('create-folder-spinner')).toBeInTheDocument()

    // Verify buttons are disabled during submission
    expect(screen.getByRole('button', {name: /Cancel/i})).toBeDisabled()
    expect(screen.getByRole('button', {name: /Create Folder/i})).toBeDisabled()
  })

  it('does not close when there is an error', async () => {
    const user = userEvent.setup()
    fetchMock.post(/.*\/folders/, 500, {overwriteRoutes: true})
    renderComponent()
    const createFolderButton = screen.getByRole('button', {name: /Create Folder/i})
    await user.click(createFolderButton)
    expect(defaultProps.onRequestClose).not.toHaveBeenCalled()
  })

  it('shows validation error when folder name is greater than 255 characters', async () => {
    const user = userEvent.setup()
    renderComponent()
    const input = screen.getByRole('textbox', {name: /Folder Name/i})
    const name = 'a'.repeat(256)
    // userEvent.type is flaky with long strings
    fireEvent.change(input, {target: {value: name}})
    const createFolderButton = screen.getByRole('button', {name: /Create Folder/i})
    await user.click(createFolderButton)
    expect(await screen.findByText(/Folder name cannot exceed 255 characters/i)).toBeInTheDocument()
  })

  it('submits with folder name of 255 characters', async () => {
    const user = userEvent.setup()
    renderComponent()
    const input = screen.getByRole('textbox', {name: /Folder Name/i})
    const name = 'a'.repeat(255)
    // userEvent.type is flaky with long strings
    fireEvent.change(input, {target: {value: name}})
    const createFolderButton = screen.getByRole('button', {name: /Create Folder/i})
    await user.click(createFolderButton)

    await waitFor(() => {
      expect(fetchMock.lastCall()?.[1]?.body).toEqual(`{"name":"${name}"}`)
    })
  })
})
