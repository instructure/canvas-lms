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
import {fireEvent, render, screen} from '@testing-library/react'
import {ConfiguredTextInput} from '../ConfiguredTextInput'

describe('ConfiguredTextInput', () => {
  it('renders with the correct label and value', () => {
    const label = 'Test Label'
    const inputValue = 'Test Value'

    render(<ConfiguredTextInput label={label} inputValue={inputValue} onChange={() => {}} />)

    expect(screen.getByLabelText(label)).toBeInTheDocument()
    expect(screen.getByDisplayValue(inputValue)).toBeInTheDocument()
  })

  it('calls onChange when input value changes', () => {
    const label = 'Test Label'
    const inputValue = 'Test Value'
    const expectedValue = 'New Value'
    const handleChange = jest.fn()

    render(<ConfiguredTextInput label={label} inputValue={inputValue} onChange={handleChange} />)

    const input = screen.getByLabelText(label)
    fireEvent.change(input, {target: {value: expectedValue}})

    expect(handleChange).toHaveBeenCalledWith(expectedValue)
  })
})
