/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {render, screen, within} from '@testing-library/react'
import {AddBlockModal} from '../AddBlockModal'
import userEvent from '@testing-library/user-event'

describe('AddBlockModal', () => {
  let onDismissMock: jest.Mock
  let onAddBlockMock: jest.Mock

  const renderModal = (props: Partial<React.ComponentProps<typeof AddBlockModal>>) => {
    render(
      <AddBlockModal
        open={true}
        onDismiss={onDismissMock}
        onAddBlock={onAddBlockMock}
        {...props}
      />,
    )
  }

  beforeEach(() => {
    onDismissMock = jest.fn()
    onAddBlockMock = jest.fn()
  })

  it('does not renders when open is false', () => {
    renderModal({open: false})
    expect(screen.queryByText('Add new block')).not.toBeInTheDocument()
    expect(screen.queryByText('Add to page')).not.toBeInTheDocument()
  })

  it('renders', async () => {
    renderModal({})
    expect(await screen.findByText('Add new block')).toBeInTheDocument()
    expect(await screen.findByText('Add to page')).toBeInTheDocument()
  })

  it('calls onDismiss when close button is clicked', async () => {
    renderModal({})
    const closeButtonWrapper = await screen.findByTestId('add-modal-close-button')
    const closeButton = within(closeButtonWrapper).getByRole('button')
    await userEvent.click(closeButton)
    expect(onDismissMock).toHaveBeenCalled()
  })

  it('calls onDismiss when cancel button is clicked', async () => {
    renderModal({})
    const cancelButton = await screen.findByTestId('add-modal-cancel-button')
    await userEvent.click(cancelButton)
    expect(onDismissMock).toHaveBeenCalled()
  })

  it('calls onAddBlock when "Add to page" button is clicked', async () => {
    renderModal({})
    const addButton = await screen.findByRole('button', {name: 'Add to page'})
    await userEvent.click(addButton)
    expect(onAddBlockMock).toHaveBeenCalledWith('new_block')
  })

  it('calls onDismiss when "Add to page" button is clicked', async () => {
    renderModal({})
    const addButton = await screen.findByRole('button', {name: 'Add to page'})
    await userEvent.click(addButton)
    expect(onDismissMock).toHaveBeenCalled()
  })
})
