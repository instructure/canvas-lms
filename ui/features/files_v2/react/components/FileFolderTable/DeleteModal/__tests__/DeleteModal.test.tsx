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

import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {FileManagementProvider} from '../../../../contexts/FileManagementContext'
import {RowFocusProvider} from '../../../../contexts/RowFocusContext'
import {RowsProvider} from '../../../../contexts/RowsContext'
import {createMockFileManagementContext} from '../../../../__tests__/createMockContext'
import {FAKE_FILES, FAKE_FOLDERS, FAKE_FOLDERS_AND_FILES} from '../../../../../fixtures/fakeData'
import {DeleteModal} from '../DeleteModal'
import {resetAndGetFilesEnv} from '../../../../../utils/filesEnvUtils'
import {createFilesContexts} from '../../../../../fixtures/fileContexts'
import {mockRowFocusContext, mockRowsContext} from '../../__tests__/testUtils'
import {BulkItemRequestsError} from '../../../../queries/BultItemRequestsError'
import {makeBulkItemRequests} from '../../../../queries/makeBulkItemRequests'
import {deleteItem} from '../../../../queries/deleteItem'
import {UnauthorizedError} from '../../../../../utils/apiUtils'

jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashSuccess: jest.fn(() => jest.fn()),
  showFlashWarning: jest.fn(() => jest.fn()),
  showFlashError: jest.fn(() => jest.fn()),
}))

// Mock makeBulkItemRequests function
jest.mock('../../../../queries/makeBulkItemRequests', () => ({
  makeBulkItemRequests: jest.fn(),
}))

// Mock Sentry
jest.mock('@sentry/react', () => ({
  captureException: jest.fn(),
}))

const mockMakeBulkItemRequests = makeBulkItemRequests as jest.MockedFunction<
  typeof makeBulkItemRequests
>
const mockFlashAlerts = require('@canvas/alerts/react/FlashAlert')
const {captureException} = require('@sentry/react')

const defaultProps = {
  open: true,
  items: FAKE_FOLDERS_AND_FILES,
  onClose: jest.fn(),
}

const renderComponent = (props?: any) =>
  render(
    <FileManagementProvider value={createMockFileManagementContext()}>
      <RowFocusProvider value={mockRowFocusContext}>
        <RowsProvider value={mockRowsContext}>
          <DeleteModal {...defaultProps} {...props} />
        </RowsProvider>
      </RowFocusProvider>
    </FileManagementProvider>,
  )

const renderComponentWithCustomContexts = (
  props?: any,
  customRowFocusContext?: any,
  customRowsContext?: any,
) =>
  render(
    <FileManagementProvider value={createMockFileManagementContext()}>
      <RowFocusProvider value={customRowFocusContext || mockRowFocusContext}>
        <RowsProvider value={customRowsContext || mockRowsContext}>
          <DeleteModal {...defaultProps} {...props} />
        </RowsProvider>
      </RowFocusProvider>
    </FileManagementProvider>,
  )

describe('DeleteModal', () => {
  let user: ReturnType<typeof userEvent.setup>

  const clickDeleteButton = async () => {
    const deleteButton = await screen.findByTestId('modal-delete-button')
    await user.click(deleteButton)
    return deleteButton
  }

  beforeAll(() => {
    const filesContexts = createFilesContexts()
    resetAndGetFilesEnv(filesContexts)
  })

  beforeEach(() => {
    user = userEvent.setup()
    mockMakeBulkItemRequests.mockReset()
    jest.clearAllMocks()
  })

  it('renders header', async () => {
    renderComponent()
    expect(screen.getByText('Delete Items')).toBeInTheDocument()
  })

  describe('renders body', () => {
    describe('with preview', () => {
      it('for a files and folders', async () => {
        renderComponent()
        expect(
          await screen.findByText(`Selected Items (${FAKE_FOLDERS_AND_FILES.length})`),
        ).toBeInTheDocument()
      })

      it('for a file', async () => {
        renderComponent({items: [FAKE_FILES[0]]})
        expect(await screen.findByText(FAKE_FILES[0].display_name)).toBeInTheDocument()
      })

      it('for a folder', async () => {
        renderComponent({items: [FAKE_FOLDERS[0]]})
        expect(await screen.findByText(FAKE_FOLDERS[0].name)).toBeInTheDocument()
      })
    })
  })

  it('renders footer', async () => {
    renderComponent()
    expect(screen.getByTestId('modal-delete-button')).toBeInTheDocument()
    expect(screen.getByTestId('modal-cancel-button')).toBeInTheDocument()
  })

  it('disables delete button and renders spinner while deleting', async () => {
    mockMakeBulkItemRequests.mockImplementation(() => new Promise(() => {})) // Never resolves to keep loading state
    renderComponent()

    const deleteButton = await clickDeleteButton()

    const spinner = await screen.findByTestId('delete-spinner')
    expect(spinner).toBeInTheDocument()
    expect(deleteButton).toBeDisabled()
  })

  describe('successful deletion', () => {
    it('calls makeBulkItemRequests and shows success message for multiple items', async () => {
      const onCloseMock = jest.fn()
      mockMakeBulkItemRequests.mockResolvedValue(undefined)

      renderComponent({onClose: onCloseMock})

      await clickDeleteButton()

      expect(mockMakeBulkItemRequests).toHaveBeenCalledWith(FAKE_FOLDERS_AND_FILES, deleteItem)
      expect(mockFlashAlerts.showFlashSuccess).toHaveBeenCalledWith(
        `${FAKE_FOLDERS_AND_FILES.length} items deleted successfully.`,
      )
      expect(onCloseMock).toHaveBeenCalled()
    })

    it('shows success message for single item deletion', async () => {
      mockMakeBulkItemRequests.mockResolvedValue(undefined)

      renderComponent({items: [FAKE_FILES[0]]})

      await clickDeleteButton()

      expect(mockFlashAlerts.showFlashSuccess).toHaveBeenCalledWith('1 item deleted successfully.')
    })
  })

  describe('error handling', () => {
    it('handles UnauthorizedError by setting session expired', async () => {
      const mockSetSessionExpired = jest.fn()
      const mockRowsContextWithExpired = {
        ...mockRowsContext,
        setSessionExpired: mockSetSessionExpired,
      }

      mockMakeBulkItemRequests.mockRejectedValue(new UnauthorizedError())

      renderComponentWithCustomContexts({}, undefined, mockRowsContextWithExpired)

      await clickDeleteButton()

      expect(mockSetSessionExpired).toHaveBeenCalledWith(true)
    })

    it('shows error message when all items fail to delete', async () => {
      const failedItems = [FAKE_FILES[0], FAKE_FOLDERS[0]]
      const deleteError = new BulkItemRequestsError('Failed to delete some items', failedItems)

      mockMakeBulkItemRequests.mockRejectedValue(deleteError)
      renderComponent({items: failedItems})

      await clickDeleteButton()

      const expectedMessage = 'Failed to delete all selected items. Please try again.'
      expect(mockFlashAlerts.showFlashError).toHaveBeenCalledWith(expectedMessage)
    })

    it('shows warning message when some items fail to delete', async () => {
      const allItems = [FAKE_FILES[0], FAKE_FOLDERS[0], FAKE_FILES[1]]
      const failedItems = [FAKE_FILES[0]] // Only one item fails
      const deleteError = new BulkItemRequestsError('Failed to delete some items', failedItems)

      mockMakeBulkItemRequests.mockRejectedValue(deleteError)
      renderComponent({items: allItems})

      await clickDeleteButton()

      const expectedMessage = `Failed to delete ${failedItems.length} of the ${allItems.length} selected items. Please try again.`
      expect(mockFlashAlerts.showFlashWarning).toHaveBeenCalledWith(expectedMessage)
    })

    it('handles unexpected errors and captures them in Sentry', async () => {
      const unexpectedError = new Error('Network error')

      mockMakeBulkItemRequests.mockRejectedValue(unexpectedError)
      renderComponent()

      await clickDeleteButton()

      expect(mockFlashAlerts.showFlashError).toHaveBeenCalledWith(
        'An error occurred while deleting the items. Please try again.',
      )
      expect(captureException).toHaveBeenCalledWith(unexpectedError)
    })

    it('always calls onClose and sets row focus after error', async () => {
      const onCloseMock = jest.fn()
      const mockSetRowToFocus = jest.fn()
      const mockRowFocusContextWithSetter = {
        ...mockRowFocusContext,
        setRowToFocus: mockSetRowToFocus,
      }

      mockMakeBulkItemRequests.mockRejectedValue(new Error('Some error'))

      renderComponentWithCustomContexts(
        {onClose: onCloseMock, rowIndex: 5},
        mockRowFocusContextWithSetter,
      )

      await clickDeleteButton()

      expect(onCloseMock).toHaveBeenCalled()
      expect(mockSetRowToFocus).toHaveBeenCalledWith(5)
    })
  })
})
