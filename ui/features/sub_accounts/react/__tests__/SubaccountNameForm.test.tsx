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

import {fireEvent, render, waitFor} from '@testing-library/react'
import SubaccountNameForm from '../SubaccountNameForm'
import fetchMock from 'fetch-mock'
import userEvent from '@testing-library/user-event'

describe('SubaccountNameForm', () => {
  const props = {
    accountName: 'New Name',
    accountId: '1',
    onSuccess: jest.fn(),
    onCancel: jest.fn(),
  }

  const updatedAccount = {
    id: '1',
    name: 'Updated Name',
    sub_account_count: 0,
    course_count: 0,
  }

  beforeEach(() => {
    fetchMock.restore()
    jest.resetAllMocks()
  })

  it('renders an input with submission buttons', () => {
    const {getByTestId} = render(<SubaccountNameForm {...props} />)

    expect(getByTestId('account-name-input')).toBeInTheDocument()
    expect(getByTestId('save-button')).toBeInTheDocument()
    expect(getByTestId('cancel-button')).toBeInTheDocument()
  })

  it('renders validation error for blank name input', async () => {
    const user = userEvent.setup()
    const {getByTestId, getByText} = render(<SubaccountNameForm {...props} accountName="" />)

    await user.click(getByTestId('save-button'))
    expect(getByText('Name is required')).toBeInTheDocument()
  })

  it('creates new subaccount when passed in name is blank', async () => {
    const path = `/accounts/${props.accountId}/sub_accounts`
    const user = userEvent.setup()
    const onSuccess = jest.fn()
    const {getByTestId} = render(
      <SubaccountNameForm {...props} onSuccess={onSuccess} accountName="" />,
    )
    fetchMock.post(path, updatedAccount)

    fireEvent.change(getByTestId('account-name-input'), {target: {value: 'New Name'}})
    await user.click(getByTestId('save-button'))
    await waitFor(() => expect(fetchMock.called(path, 'POST')).toBe(true))
    expect(onSuccess).toBeCalledTimes(1)
  })

  it('updates existing subaccount when passed in name is not blank', async () => {
    const path = `/accounts/${props.accountId}`
    const user = userEvent.setup()
    const onSuccess = jest.fn()
    const {getByTestId} = render(<SubaccountNameForm {...props} onSuccess={onSuccess} />)
    fetchMock.put(path, {account: updatedAccount})

    await user.click(getByTestId('save-button'))
    await waitFor(() => expect(fetchMock.called(path, 'PUT')).toBe(true))
    expect(onSuccess).toBeCalledTimes(1)
  })

  it('triggers callback when cancelling', async () => {
    const user = userEvent.setup()
    const onCancel = jest.fn()
    const {getByTestId} = render(<SubaccountNameForm {...props} onCancel={onCancel} />)

    await user.click(getByTestId('cancel-button'))
    expect(onCancel).toBeCalledTimes(1)
  })
})
