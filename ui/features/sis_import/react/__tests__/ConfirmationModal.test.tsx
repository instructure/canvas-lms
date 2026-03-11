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
import {render, fireEvent} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {ConfirmationModal} from '../ConfirmationModal'

const ACCOUNT_NAME = 'Stride Academy'

const onSubmit = vi.fn()
const onRequestClose = vi.fn()

const defaultProps = {
  isOpen: true,
  onSubmit,
  onRequestClose,
  showBatchModeWarning: false,
  showSiteAdminConfirmation: false,
  accountName: '',
}

const renderModal = (overrides = {}) => {
  const props = {...defaultProps, ...overrides}
  return render(<ConfirmationModal {...props} />)
}

// fireEvent.change is used instead of user.type for the account name input
// because user.type causes focus to shift to a button after the first
// keystroke re-render, and any space character then activates that button
// and dismisses the modal.
const setAccountNameInput = (element: HTMLElement, value: string) => {
  fireEvent.change(element, {target: {value}})
}

describe('ConfirmationModal', () => {
  afterEach(() => {
    vi.clearAllMocks()
  })

  describe('batch mode warning only', () => {
    it('does not submit form on cancel', async () => {
      const {getByText} = renderModal({showBatchModeWarning: true})

      await userEvent.click(getByText('Cancel').closest('button')!)

      expect(onSubmit).toHaveBeenCalledTimes(0)
      expect(onRequestClose).toHaveBeenCalledTimes(1)
    })

    it('submits form on confirm', async () => {
      const {getByText} = renderModal({showBatchModeWarning: true})

      await userEvent.click(getByText('Confirm').closest('button')!)

      expect(onSubmit).toHaveBeenCalledTimes(1)
      expect(onRequestClose).toHaveBeenCalledTimes(0)
    })

    it('shows batch mode warning text', () => {
      const {getByText} = renderModal({showBatchModeWarning: true})
      expect(getByText(/this will delete everything for this term/)).toBeInTheDocument()
    })

    it('does not show site admin section', () => {
      const {queryByTestId} = renderModal({showBatchModeWarning: true})
      expect(queryByTestId('site-admin-confirm-input')).toBeNull()
    })
  })

  describe('site admin confirmation only', () => {
    it('renders site admin warning and account name', () => {
      const {getByText} = renderModal({
        showSiteAdminConfirmation: true,
        accountName: ACCOUNT_NAME,
      })
      expect(getByText('Confirm SIS Import')).toBeInTheDocument()
      expect(getByText(`Account: ${ACCOUNT_NAME}`)).toBeInTheDocument()
      expect(getByText(/import SIS data as a site admin/)).toBeInTheDocument()
    })

    it('shows error when wrong name is typed and confirm clicked', async () => {
      const user = userEvent.setup()
      const {getByTestId, findByText} = renderModal({
        showSiteAdminConfirmation: true,
        accountName: ACCOUNT_NAME,
      })

      setAccountNameInput(getByTestId('site-admin-confirm-input'), 'Wrong Name')
      await user.click(getByTestId('site-admin-confirm-btn'))

      expect(await findByText(/Account name does not match/)).toBeInTheDocument()
      expect(onSubmit).not.toHaveBeenCalled()
    })

    it('calls onSubmit when correct name is typed', async () => {
      const user = userEvent.setup()
      const {getByTestId} = renderModal({
        showSiteAdminConfirmation: true,
        accountName: ACCOUNT_NAME,
      })

      setAccountNameInput(getByTestId('site-admin-confirm-input'), ACCOUNT_NAME)
      await user.click(getByTestId('site-admin-confirm-btn'))

      expect(onSubmit).toHaveBeenCalledTimes(1)
    })

    it('accepts case-insensitive account name', async () => {
      const user = userEvent.setup()
      const {getByTestId} = renderModal({
        showSiteAdminConfirmation: true,
        accountName: ACCOUNT_NAME,
      })

      setAccountNameInput(getByTestId('site-admin-confirm-input'), 'stride academy')
      await user.click(getByTestId('site-admin-confirm-btn'))

      expect(onSubmit).toHaveBeenCalledTimes(1)
    })

    it('calls onRequestClose when cancel is clicked', async () => {
      const user = userEvent.setup()
      const {getByTestId} = renderModal({
        showSiteAdminConfirmation: true,
        accountName: ACCOUNT_NAME,
      })

      await user.click(getByTestId('site-admin-cancel-btn'))

      expect(onRequestClose).toHaveBeenCalledTimes(1)
    })

    it('clears error when user types after an error', async () => {
      const user = userEvent.setup()
      const {getByTestId, findByText, queryByText} = renderModal({
        showSiteAdminConfirmation: true,
        accountName: ACCOUNT_NAME,
      })

      setAccountNameInput(getByTestId('site-admin-confirm-input'), 'Wrong')
      await user.click(getByTestId('site-admin-confirm-btn'))
      expect(await findByText(/Account name does not match/)).toBeInTheDocument()

      setAccountNameInput(getByTestId('site-admin-confirm-input'), 'Wrongx')
      expect(queryByText(/Account name does not match/)).not.toBeInTheDocument()
    })
  })

  describe('both site admin and batch mode', () => {
    it('shows both sections in the same modal', () => {
      const {getByText, getByTestId} = renderModal({
        showSiteAdminConfirmation: true,
        showBatchModeWarning: true,
        accountName: ACCOUNT_NAME,
      })
      expect(getByText(`Account: ${ACCOUNT_NAME}`)).toBeInTheDocument()
      expect(getByText(/import SIS data as a site admin/)).toBeInTheDocument()
      expect(getByText(/this will delete everything for this term/)).toBeInTheDocument()
      expect(getByTestId('site-admin-confirm-input')).toBeInTheDocument()
    })

    it('requires account name before confirming', async () => {
      const user = userEvent.setup()
      const {getByTestId, findByText} = renderModal({
        showSiteAdminConfirmation: true,
        showBatchModeWarning: true,
        accountName: ACCOUNT_NAME,
      })

      await user.click(getByTestId('site-admin-confirm-btn'))
      expect(await findByText(/Account name does not match/)).toBeInTheDocument()
      expect(onSubmit).not.toHaveBeenCalled()

      setAccountNameInput(getByTestId('site-admin-confirm-input'), ACCOUNT_NAME)
      await user.click(getByTestId('site-admin-confirm-btn'))
      expect(onSubmit).toHaveBeenCalledTimes(1)
    })
  })

  it('does not render when isOpen is false', () => {
    const {queryByText} = renderModal({isOpen: false})
    expect(queryByText('Confirm SIS Import')).not.toBeInTheDocument()
  })
})
