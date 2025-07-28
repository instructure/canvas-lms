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
import {fireEvent, render} from '@testing-library/react'
import {ConfiguredTextInput} from '../ConfiguredTextInput'

describe('ConfiguredTextInput', () => {
  const label = 'Test Label'
  const inputValue = 'Test Value'

  it('renders with the correct label and value', () => {
    const {getByLabelText, getByDisplayValue} = render(
      <ConfiguredTextInput label={label} inputValue={inputValue} onChange={() => {}} />,
    )

    expect(getByLabelText(label)).toBeInTheDocument()
    expect(getByDisplayValue(inputValue)).toBeInTheDocument()
  })

  it('calls onChange when input value changes', () => {
    const expectedValue = 'New Value'
    const handleChange = jest.fn()

    const {getByLabelText} = render(
      <ConfiguredTextInput label={label} inputValue={inputValue} onChange={handleChange} />,
    )

    const input = getByLabelText(label)
    fireEvent.change(input, {target: {value: expectedValue}})

    expect(handleChange).toHaveBeenCalledWith(expectedValue)
  })

  it('renders with disabled', () => {
    const {getByDisplayValue} = render(
      <ConfiguredTextInput
        label={label}
        inputValue={inputValue}
        onChange={() => {}}
        disabled={true}
      />,
    )
    expect(getByDisplayValue(inputValue)).toBeDisabled()
  })
})
