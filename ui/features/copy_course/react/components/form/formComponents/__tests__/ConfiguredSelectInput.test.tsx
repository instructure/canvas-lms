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
import {render, fireEvent, waitFor} from '@testing-library/react'
import {ConfiguredSelectInput} from '../ConfiguredSelectInput'

describe('ConfiguredSelectInput', () => {
  const options = [
    {id: '1', name: 'Option 1'},
    {id: '2', name: 'Option 2'},
    {id: '3', name: 'Option 3'},
  ]

  const label = 'Test Label'
  const assistiveText = 'Use arrow keys to navigate options.'
  const defaultInputValue = 'Option 1'

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

  it('renders with messages', () => {
    const messages = [{text: 'Error message', type: 'error'}]
    const {getByText} = renderConfiguredSelectInput({messages})
    expect(getByText('Error message')).toBeInTheDocument()
  })

  it('renders Select with filtered options when typing', async () => {
    const { getByLabelText, queryByText } = renderConfiguredSelectInput({
      searchable: true,
      defaultInputValue: ''
    })

    fireEvent.click(getByLabelText(label))
    fireEvent.change(getByLabelText(label), { target: { value: 'Option 2' } })

    await waitFor(() => {
      expect(queryByText('Option 2')).toBeInTheDocument()
      expect(queryByText('Option 1')).not.toBeInTheDocument()
      expect(queryByText('Option 3')).not.toBeInTheDocument()
    })
  })

  it('selects an option when clicked and calls onSelect', () => {
    const onSelect = jest.fn()
    const { getByLabelText, getByText, getByDisplayValue } = renderConfiguredSelectInput({
      searchable: true,
      defaultInputValue: '',
      onSelect
    })

    fireEvent.click(getByLabelText(label))
    fireEvent.click(getByText('Option 3'))

    expect(getByDisplayValue('Option 3')).toBeInTheDocument()
    expect(onSelect).toHaveBeenCalledWith('3')
  })

  it('automatically selects first option if no defaultInputValue is provided', () => {
    const onSelect = jest.fn()
    const { getByDisplayValue } = renderConfiguredSelectInput({
      searchable: true,
      defaultInputValue: undefined,
      onSelect
    })

    expect(getByDisplayValue('Option 1')).toBeInTheDocument()
    expect(onSelect).toHaveBeenCalledWith('1')
  })

  it('shows "No results" if filtering returns nothing', async () => {
    const { getByLabelText, findByText } = renderConfiguredSelectInput({
      searchable: true,
      defaultInputValue: ''
    })

    fireEvent.change(getByLabelText(label), { target: { value: 'Not an option' } })
    expect(await findByText('No results')).toBeInTheDocument()
  })

  it('groups options into Active, Future, Past, and Unknown based on dates', async () => {
    const now = new Date()
    const makeDate = (offset: number) => {
      const d = new Date()
      d.setDate(now.getDate() + offset)
      return d.toISOString()
    }

    const groupedOptions = [
      { id: '1', name: 'Active Term', startAt: makeDate(-1), endAt: makeDate(1) },
      { id: '2', name: 'Future Term', startAt: makeDate(5), endAt: makeDate(10) },
      { id: '3', name: 'Past Term', startAt: makeDate(-10), endAt: makeDate(-5) },
      { id: '4', name: 'Unscheduled Term' }
    ]

    const { getByLabelText, getByText } = renderConfiguredSelectInput({
      options: groupedOptions,
      defaultInputValue: '',
      searchable: true
    })

    fireEvent.click(getByLabelText(label))

    // Group labels
    expect(getByText('Active')).toBeInTheDocument()
    expect(getByText('Future')).toBeInTheDocument()
    expect(getByText('Past')).toBeInTheDocument()
    expect(getByText('Unscheduled')).toBeInTheDocument()

    // Term names
    expect(getByText('Active Term')).toBeInTheDocument()
    expect(getByText('Future Term')).toBeInTheDocument()
    expect(getByText('Past Term')).toBeInTheDocument()
    expect(getByText('Unscheduled Term')).toBeInTheDocument()
  })

})
