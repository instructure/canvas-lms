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
import {render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import GroupEditForm from '../GroupEditForm'

describe('GroupEditForm - Basic', () => {
  let onCloseHandler, onSubmit, user

  beforeAll(() => {
    jest.useFakeTimers()
  })

  afterAll(() => {
    jest.useRealTimers()
  })

  const defaultProps = (props = {}) => ({
    isOpen: true,
    onSubmit,
    onCloseHandler,
    ...props,
  })

  beforeEach(() => {
    onCloseHandler = jest.fn()
    onSubmit = jest.fn()
    user = userEvent.setup({advanceTimers: jest.advanceTimersByTime})
  })

  afterEach(() => {
    jest.clearAllMocks()
    jest.runOnlyPendingTimers()
  })

  it('renders form with empty data', async () => {
    const {getByTestId} = render(<GroupEditForm {...defaultProps()} />)
    expect(getByTestId('group-name-input')).toBeInTheDocument()
    expect(getByTestId('group-description-input')).toBeInTheDocument()
  })

  it('renders form with initial title', async () => {
    const initialValues = {
      title: 'The Group Name',
      description: 'The Group Description',
    }
    const {getByTestId} = render(<GroupEditForm {...defaultProps({initialValues})} />)
    const input = getByTestId('group-name-input')
    expect(input).toHaveValue('The Group Name')
  })

  it('validates name', async () => {
    const {getByTestId, queryByText} = render(<GroupEditForm {...defaultProps()} />)
    const name = getByTestId('group-name-input')

    await user.clear(name)
    await user.tab()

    await waitFor(
      () => {
        expect(queryByText('This field is required')).toBeInTheDocument()
      },
      {timeout: 1000},
    )

    await user.type(name, 'a')
    await waitFor(
      () => {
        expect(queryByText('This field is required')).not.toBeInTheDocument()
      },
      {timeout: 1000},
    )
  })

  it('renders without Close button if isOpen is false', () => {
    const {queryByRole} = render(<GroupEditForm {...defaultProps({isOpen: false})} />)
    expect(queryByRole('button', {name: /close/i})).not.toBeInTheDocument()
  })

  it('calls onCloseHandler on Close button click', async () => {
    const {getByRole} = render(<GroupEditForm {...defaultProps()} />)
    const closeButton = getByRole('button', {name: /close/i})

    await user.click(closeButton)
    expect(onCloseHandler).toHaveBeenCalledTimes(1)
  })

  it('calls onCloseHandler on Cancel button click', async () => {
    const {getByTestId} = render(<GroupEditForm {...defaultProps()} />)
    const cancelButton = getByTestId('group-edit-cancel-button')

    await user.click(cancelButton)
    expect(onCloseHandler).toHaveBeenCalledTimes(1)
  })
})
