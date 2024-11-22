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
import {render, screen, fireEvent} from '@testing-library/react'
import {ConfiguredSelectInput} from '../ConfiguredSelectInput'

describe('ConfiguredSelectInput', () => {
  const options = [
    {id: '1', label: 'Option 1'},
    {id: '2', label: 'Option 2'},
    {id: '3', label: 'Option 3'},
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
    renderConfiguredSelectInput()
    expect(screen.getByLabelText(label)).toBeInTheDocument()
    expect(screen.getByText(assistiveText)).toBeInTheDocument()
    expect(screen.getByDisplayValue(defaultInputValue)).toBeInTheDocument()
  })

  it('shows options when clicked', () => {
    renderConfiguredSelectInput()
    fireEvent.click(screen.getByLabelText('Test Label'))
    options.forEach(option => {
      expect(screen.getByText(option.label)).toBeInTheDocument()
    })
  })

  it('selects an option when clicked', () => {
    renderConfiguredSelectInput()
    fireEvent.click(screen.getByLabelText(label))
    fireEvent.click(screen.getByText(options[1].label))
    expect(screen.getByDisplayValue(options[1].label)).toBeInTheDocument()
  })

  it('calls the onSelect mock on selection', () => {
    const onSelect = jest.fn()
    renderConfiguredSelectInput({onSelect})
    fireEvent.click(screen.getByLabelText(label))
    fireEvent.click(screen.getByText(options[1].label))
    expect(onSelect).toHaveBeenCalledWith(options[1].id)
  })
})
