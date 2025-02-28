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
import GroupLimitInput, {GroupLimitInputProps} from '../GroupLimitInput'

describe('GroupLimitInput', () => {
  const setup = (props?: Partial<GroupLimitInputProps>) => {
    const defaultProps: GroupLimitInputProps = {
      id: '1',
      initialValue: ''
    }
    return <GroupLimitInput {...defaultProps} {...props} />
  }

  it('renders correctly with initial value', () => {
    const {getByTestId} = render(setup({initialValue: '5'}))
    const input = getByTestId('group_limit_input_1')
    expect(input).toBeInTheDocument()
    expect(input).toHaveValue('5')
  })

  it('updates value when changed', () => {
    const {getByTestId} = render(setup())
    const input = getByTestId('group_limit_input_1')
    fireEvent.change(input, { target: { value: '10' } })
    expect(input).toHaveValue('10')
  })

  it('shows error if value is not a number', () => {
    const {getByTestId, getByText} = render(setup())
    const input = getByTestId('group_limit_input_1')
    fireEvent.change(input, { target: { value: 'abc' } })
    fireEvent.blur(input)
    expect(getByText('Value must be a whole number')).toBeInTheDocument()
  })

  it('shows error if value is less than 2', () => {
    const {getByTestId, getByText} = render(setup())
    const input = getByTestId('group_limit_input_1')
    fireEvent.change(input, { target: { value: '1' } })
    fireEvent.blur(input)
    expect(getByText('Value must be greater than or equal to 2')).toBeInTheDocument()
  })

  it('shows error value is not a whole number', () => {
    const {getByTestId, getByText} = render(setup())
    const input = getByTestId('group_limit_input_1')
    fireEvent.change(input, { target: { value: '3.5' } })
    fireEvent.blur(input)
    expect(getByText('Value must be a whole number')).toBeInTheDocument()
  })

  it('clears error messages when input is changed', () => {
    const {getByTestId, getByText, queryByText} = render(setup())
    const input = getByTestId('group_limit_input_1')
    fireEvent.change(input, { target: { value: '1' } })
    fireEvent.blur(input)
    expect(getByText('Value must be greater than or equal to 2')).toBeInTheDocument()
    fireEvent.change(input, { target: { value: '3' } })
    expect(queryByText('Value must be greater than or equal to 2')).not.toBeInTheDocument()
  })
})
