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

import {render, waitFor} from '@testing-library/react'
import SubaccountItem from '../SubaccountItem'
import userEvent from '@testing-library/user-event'
import fetchMock from 'fetch-mock'

const account = {id: '1', name: 'Account_Name', sub_account_count: 3, course_count: 1}

const props = {
  account,
  depth: 0,
  onAdd: jest.fn(),
  onEditSaved: jest.fn(),
  onDelete: jest.fn(),
  onExpand: jest.fn(),
  onCollapse: jest.fn(),
  isExpanded: true,
  canDelete: true,
  show: true,
  isFocus: false,
}

describe('SubaccountItem', () => {
  afterEach(() => {
    jest.resetAllMocks()
  })

  it('renders name and all buttons', () => {
    const {getByText, getByTestId} = render(<SubaccountItem {...props} />)

    expect(getByText('Account_Name')).toBeInTheDocument()
    expect(getByText('3 Sub-Accounts')).toBeInTheDocument()
    expect(getByText('1 Course')).toBeInTheDocument()
    expect(getByTestId(`link_${account.id}`)).toHaveAttribute('href', `/accounts/${account.id}`)

    expect(getByTestId(`collapse-${account.id}`)).toBeInTheDocument()
    expect(getByTestId(`add-${account.id}`)).toBeInTheDocument()
    expect(getByTestId(`edit-${account.id}`)).toBeInTheDocument()
    expect(getByTestId(`delete-${account.id}`)).toBeInTheDocument()
  })

  it('disables delete button if top-level account', () => {
    const {queryByTestId, getByTestId} = render(<SubaccountItem {...props} canDelete={false} />)

    expect(getByTestId(`collapse-${account.id}`)).toBeInTheDocument()
    expect(getByTestId(`add-${account.id}`)).toBeInTheDocument()
    expect(getByTestId(`edit-${account.id}`)).toBeInTheDocument()
    expect(queryByTestId(`delete-${account.id}`)).toBeDisabled()
  })

  it('swaps to expand button when collapsed', async () => {
    const onExpand = jest.fn()
    const user = userEvent.setup()
    const {queryByTestId, getByTestId} = render(
      <SubaccountItem {...props} isExpanded={false} onExpand={onExpand} />,
    )

    expect(getByTestId(`expand-${account.id}`)).toBeInTheDocument()
    expect(queryByTestId(`collapse-${account.id}`)).toBeNull()

    await user.click(getByTestId(`expand-${account.id}`))
    expect(onExpand).toBeCalledTimes(1)
  })

  it('triggers callbacks for each respective icon button', async () => {
    const onAdd = jest.fn()
    const onDelete = jest.fn()
    const onCollapse = jest.fn()
    const user = userEvent.setup()
    const {getByTestId} = render(
      <SubaccountItem {...props} onAdd={onAdd} onDelete={onDelete} onCollapse={onCollapse} />,
    )

    await user.click(getByTestId(`collapse-${account.id}`))
    expect(onCollapse).toBeCalledTimes(1)

    await user.click(getByTestId(`add-${account.id}`))
    expect(onAdd).toBeCalledTimes(1)

    await user.click(getByTestId(`delete-${account.id}`))
    expect(onDelete).toBeCalledTimes(1)
  })

  it('renders a form when editing and triggers callback on save', async () => {
    const onEditSaved = jest.fn()
    const user = userEvent.setup()
    const updatePath = `/accounts/${account.id}`
    fetchMock.put(updatePath, {account})
    const {queryByTestId, getByTestId} = render(
      <SubaccountItem {...props} onEditSaved={onEditSaved} />,
    )

    await user.click(getByTestId(`edit-${account.id}`))

    // renders form
    expect(getByTestId('account-name-input')).toBeInTheDocument()
    expect(queryByTestId(`link_${account.id}`)).toBeNull()

    // submit form
    await user.click(getByTestId('save-button'))
    await waitFor(() => {
      expect(onEditSaved).toBeCalledTimes(1)
      expect(fetchMock.called(updatePath, 'PUT')).toBeTruthy()
    })
  })
})
