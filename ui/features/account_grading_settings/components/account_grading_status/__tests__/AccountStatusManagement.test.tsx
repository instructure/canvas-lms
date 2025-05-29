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
import {BrowserRouter, Route, Routes} from 'react-router-dom'
import {MockedProvider} from '@apollo/client/testing'
import {render, fireEvent, waitFor, act, cleanup} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {
  AccountStatusManagement,
  type AccountStatusManagementProps,
} from '../AccountStatusManagement'
import {setupGraphqlMocks} from './fixtures'
import fakeENV from '@canvas/test-utils/fakeENV'
import {destroyContainer as destroyFlashAlertContainer} from '@canvas/alerts/react/FlashAlert'

describe('Account Grading Status Management', () => {
  const renderGradingStatusManagement = (props: Partial<AccountStatusManagementProps>) => {
    const componentProps: AccountStatusManagementProps = {
      rootAccountId: '2',
      isRootAccount: true,
      isExtendedStatusEnabled: true,
      ...props,
    }
    return render(
      <BrowserRouter basename="">
        <Routes>
          <Route
            path="/"
            element={
              <MockedProvider mocks={setupGraphqlMocks()} addTypename={false}>
                <AccountStatusManagement {...componentProps} />
              </MockedProvider>
            }
          />
        </Routes>
      </BrowserRouter>,
    )
  }

  const getSRAlert = () => document.querySelector('#flash_screenreader_holder')?.textContent?.trim()

  beforeEach(async () => {
    fakeENV.setup()
    await new Promise(resolve => setTimeout(resolve, 0))
  })

  afterEach(() => {
    cleanup()
    destroyFlashAlertContainer()
    fakeENV.teardown()
  })

  describe('when the account is a root account', () => {
    it('should render the component and children successfully', async () => {
      const {getByText, queryAllByTestId} = renderGradingStatusManagement({isRootAccount: true})
      await act(async () => {
        await new Promise(resolve => setTimeout(resolve, 0))
      })
      expect(getByText('Standard Statuses')).toBeInTheDocument()
      expect(getByText('Custom Statuses')).toBeInTheDocument()

      expect(queryAllByTestId(/standard-status-/)).toHaveLength(6)
      expect(queryAllByTestId(/custom\-status\-[0-9]/)).toHaveLength(2)
      expect(queryAllByTestId(/custom\-status\-new\-[0-2]/)).toHaveLength(1)
    })

    it('should not render extended status when isExtendedStatusEnabled is false', async () => {
      const {queryByText, queryAllByTestId, queryByTestId} = renderGradingStatusManagement({
        isRootAccount: true,
        isExtendedStatusEnabled: false,
      })
      await act(async () => {
        await new Promise(resolve => setTimeout(resolve, 0))
      })

      expect(queryAllByTestId(/standard-status-/)).toHaveLength(5)
      expect(queryByText('Extended')).not.toBeInTheDocument()
      expect(queryByTestId('standard-status-extended')).not.toBeInTheDocument()
    })

    it('should open a single edit popover when clicking on the edit button', async () => {
      const {getByTestId, queryAllByTestId} = renderGradingStatusManagement({isRootAccount: true})
      await act(async () => {
        await new Promise(resolve => setTimeout(resolve, 0))
      })
      expect(queryAllByTestId('edit-status-popover')).toHaveLength(0)

      const standardStatusItem = getByTestId('standard-status-1')
      expect(standardStatusItem).toBeInTheDocument()
      const standardEditButton = standardStatusItem?.querySelector('button') as Element
      expect(standardEditButton).toBeInTheDocument()
      await userEvent.click(standardEditButton)
      expect(queryAllByTestId('edit-status-popover')).toHaveLength(1)

      const customStatusItem = getByTestId('custom-status-1')
      expect(customStatusItem).toBeInTheDocument()
      const customEditButton = customStatusItem?.querySelector('button') as Element
      expect(customEditButton).toBeInTheDocument()
      await userEvent.click(customEditButton)
      expect(queryAllByTestId('edit-status-popover')).toHaveLength(1)
    })

    it('should close popover if edit button clicked again', async () => {
      const {getByTestId, queryAllByTestId} = renderGradingStatusManagement({isRootAccount: true})
      await act(async () => {
        await new Promise(resolve => setTimeout(resolve, 0))
      })
      expect(queryAllByTestId('edit-status-popover')).toHaveLength(0)

      const standardStatusItem = getByTestId('standard-status-1')
      expect(standardStatusItem).toBeInTheDocument()
      const standardEditButton = standardStatusItem?.querySelector('button') as Element
      expect(standardEditButton).toBeInTheDocument()
      fireEvent.doubleClick(standardEditButton)
      expect(queryAllByTestId('edit-status-popover')).toHaveLength(0)
    })

    it('should pick new color for status item', async () => {
      const {getByTestId} = renderGradingStatusManagement({isRootAccount: true})
      await act(async () => {
        await new Promise(resolve => setTimeout(resolve, 0))
      })
      const standardStatusItem = getByTestId('standard-status-1')
      expect(standardStatusItem.firstChild).toHaveStyle('background-color: #E40606')

      const standardEditButton = standardStatusItem?.querySelector('button') as Element
      await userEvent.click(standardEditButton)
      const newColor = getByTestId('color-picker-#F0E8EF')
      await userEvent.click(newColor)
      const saveButton = getByTestId('save-status-button')
      await userEvent.click(saveButton)

      await act(async () => {
        await new Promise(resolve => setTimeout(resolve, 0))
      })
      const updatedStatusItem = getByTestId('standard-status-1')
      expect(updatedStatusItem.firstChild).toHaveStyle('background-color: #F0E8EF')
    })

    it('should delete a custom status item', async () => {
      const {getByTestId, queryAllByTestId} = renderGradingStatusManagement({isRootAccount: true})
      await act(async () => {
        await new Promise(resolve => setTimeout(resolve, 0))
      })
      expect(queryAllByTestId(/custom\-status\-[0-9]/)).toHaveLength(2)
      expect(queryAllByTestId(/custom\-status\-new\-[0-2]/)).toHaveLength(1)
      const statusToDelete = getByTestId('custom-status-2')

      const deleteButton = statusToDelete?.querySelectorAll('button')[1]
      await userEvent.click(deleteButton)
      await act(async () => {
        await new Promise(resolve => setTimeout(resolve, 0))
      })
      const confirmDeleteButton = getByTestId('confirm-button')
      await userEvent.click(confirmDeleteButton)
      await waitFor(() => expect(queryAllByTestId(/custom\-status\-[0-9]/)).toHaveLength(1))
      expect(queryAllByTestId(/custom\-status\-new\-[0-2]/)).toHaveLength(2)

      expect(getSRAlert()).toContain('Successfully deleted custom status custom 2')
    })

    it('should pick edit color & name of custom status item', async () => {
      const {getByTestId} = renderGradingStatusManagement({isRootAccount: true})
      await act(async () => {
        await new Promise(resolve => setTimeout(resolve, 0))
      })
      const customStatusItem = getByTestId('custom-status-1')

      const customEditButton = customStatusItem?.querySelector('button') as Element
      await userEvent.click(customEditButton)
      const newColor = getByTestId('color-picker-#E5F3FC')
      await userEvent.click(newColor)
      const nameInput = getByTestId('custom-status-name-input')
      fireEvent.change(nameInput, {target: {value: 'New Status 10'}})
      expect(nameInput).toHaveValue('New Status 10')

      const saveButton = getByTestId('save-status-button')
      await userEvent.click(saveButton)
      await act(async () => {
        await new Promise(resolve => setTimeout(resolve, 0))
      })

      const customStatusItemUpdated = getByTestId('custom-status-1')
      expect(customStatusItemUpdated.textContent).toContain('New Status 10')

      expect(getSRAlert()).toContain('Custom status New Status 10 updated')
    })

    it('should add a new custom status item', async () => {
      const {getByTestId, queryAllByTestId} = renderGradingStatusManagement({isRootAccount: true})
      await act(async () => {
        await new Promise(resolve => setTimeout(resolve, 0))
      })
      const newStatusItem = getByTestId('custom-status-new-0').querySelector('span') as Element
      await userEvent.click(newStatusItem)

      const newColor = getByTestId('color-picker-#E5F3FC')
      await userEvent.click(newColor)
      const nameInput = getByTestId('custom-status-name-input')
      fireEvent.change(nameInput, {target: {value: 'New Status 11'}})
      expect(nameInput).toHaveValue('New Status 11')

      const saveButton = getByTestId('save-status-button')
      await userEvent.click(saveButton)
      await act(async () => {
        await new Promise(resolve => setTimeout(resolve, 0))
      })

      const customStatusItems = queryAllByTestId(/custom\-status\-[0-9]/)
      expect(customStatusItems).toHaveLength(3)
      expect(queryAllByTestId(/custom\-status\-new\-[0-2]/)).toHaveLength(0)
      const newItem = customStatusItems[2]

      expect(newItem.textContent).toContain('New Status 11')
      expect(newItem.firstChild).toHaveStyle('background-color: #E5F3FC')
    })
  })

  describe('when the account is a sub account', () => {
    it('should render the component and children successfully', async () => {
      const {getByText, queryAllByTestId} = renderGradingStatusManagement({isRootAccount: false})
      await act(async () => {
        await new Promise(resolve => setTimeout(resolve, 0))
      })
      expect(getByText('Standard Statuses')).toBeInTheDocument()
      expect(getByText('Custom Statuses')).toBeInTheDocument()

      expect(queryAllByTestId(/standard-status-/)).toHaveLength(6)
      expect(queryAllByTestId(/custom\-status\-[0-9]/)).toHaveLength(2)
      // cannot add new statuses from a sub account
      expect(queryAllByTestId(/custom\-status\-new\-[0-2]/)).toHaveLength(0)
    })

    it('should display status but not allow editing or deleting them', async () => {
      const {getByTestId, queryAllByTestId} = renderGradingStatusManagement({isRootAccount: false})
      await act(async () => {
        await new Promise(resolve => setTimeout(resolve, 0))
      })
      expect(queryAllByTestId('edit-status-popover')).toHaveLength(0)

      const standardStatusItem = getByTestId('standard-status-1')
      expect(standardStatusItem).toBeInTheDocument()
      const standardEditButton = standardStatusItem?.querySelector('button') as Element
      expect(standardEditButton).not.toBeInTheDocument()

      const customStatusItem = getByTestId('custom-status-1')
      expect(customStatusItem).toBeInTheDocument()
      const customEditButton = customStatusItem?.querySelector('button') as Element
      expect(customEditButton).not.toBeInTheDocument()

      const customDeleteButton = customStatusItem?.querySelector('button') as Element
      expect(customDeleteButton).not.toBeInTheDocument()
    })
  })
})
