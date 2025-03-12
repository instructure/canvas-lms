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

import React from 'react'
import { render, fireEvent } from '@testing-library/react'
import GroupSetNameInput, {GroupSetNameInputProps} from '../GroupSetNameInput'

describe('GroupSetNameInput', () => {
  const setup = (props?: Partial<GroupSetNameInputProps>) => {
    const defaultProps: GroupSetNameInputProps = {
      id: "1",
      initialValue: 'Test Group',
      getShouldShowEmptyNameError: jest.fn(() => true),
      setShouldShowEmptyNameError: jest.fn()
    }
    return <GroupSetNameInput {...defaultProps} {...props} />
  }

  it('renders without errors', () => {
    const {getByTestId} = render(setup())
    expect(getByTestId('category_1_name')).toBeInTheDocument()
  })

  it('sets the initial value if provided', () => {
    const {getByTestId} = render(setup())
    expect(getByTestId('category_1_name')).toHaveValue('Test Group')
  })

  it('updates value on input change', () => {
    const {getByTestId} = render(setup())
    const input = getByTestId('category_1_name')
    fireEvent.change(input, { target: { value: 'New Group Name' } })
    expect(input).toHaveValue('New Group Name')
  })

  it('shows an error message when the name is empty and focus is lost', () => {
    const {getByTestId, getByText} = render(setup())
    const input = getByTestId('category_1_name')
    fireEvent.focus(input)
    fireEvent.blur(input)
    expect(getByText('Name is required')).toBeInTheDocument()
  })

  it('shows an error when name exceeds 255 characters', () => {
    const {getByTestId, getByText} = render(setup())
    const input = getByTestId('category_1_name')
    fireEvent.change(input, { target: { value: 'a'.repeat(256) } })
    fireEvent.blur(input)
    expect(getByText('Name must be 255 characters or less')).toBeInTheDocument()
  })
})
