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
import {ConfiguredSelectInput} from '../ConfiguredSelectInput'

describe('ConfiguredSelectInput', () => {
  const options = [
    {id: '1', name: 'Option 1'},
    {id: '2', name: 'Option 2'},
    {id: '3', name: 'Option 3'},
  ]

  const label = 'Test Label'
  const assistiveText = 'Use arrow keys to navigate options.'
  const defaultInputValue = 'default'

  const defaultProps = {
    label,
    defaultInputValue,
    options,
    onSelect: () => {},
  }

  const renderConfiguredSelectInput = (overrideProps = {}) => {
    return render(<ConfiguredSelectInput {...defaultProps} {...overrideProps} />)
  }

  it('renders with the correct label and default option', () => {
    const {getByLabelText, getByText, getByDisplayValue} = renderConfiguredSelectInput()
    expect(getByLabelText(label)).toBeInTheDocument()
    expect(getByText(assistiveText)).toBeInTheDocument()
    expect(getByDisplayValue(defaultInputValue)).toBeInTheDocument()
  })

  it('shows options when clicked', () => {
    const {getByLabelText, getByText} = renderConfiguredSelectInput()
    fireEvent.click(getByLabelText('Test Label'))
    options.forEach(option => {
      expect(getByText(option.name)).toBeInTheDocument()
    })
  })

  it('selects an option when clicked', () => {
    const {getByLabelText, getByText, getByDisplayValue} = renderConfiguredSelectInput()
    fireEvent.click(getByLabelText(label))
    fireEvent.click(getByText(options[1].name))
    expect(getByDisplayValue(options[1].name)).toBeInTheDocument()
  })

  it('calls the onSelect mock on selection', () => {
    const onSelect = jest.fn()
    const {getByLabelText, getByText} = renderConfiguredSelectInput({onSelect})
    fireEvent.click(getByLabelText(label))
    fireEvent.click(getByText(options[1].name))
    expect(onSelect).toHaveBeenCalledWith(options[1].id)
  })

  it('renders with disabled', () => {
    const {getByDisplayValue} = renderConfiguredSelectInput({disabled: true})
    expect(getByDisplayValue(defaultInputValue)).toBeDisabled()
  })
})
