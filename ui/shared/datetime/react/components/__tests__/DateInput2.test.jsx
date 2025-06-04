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
import {fireEvent, render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import MockDate from 'mockdate'
import moment from 'moment-timezone'
import * as tz from '@instructure/moment-utils'
import CanvasDateInput2 from '../DateInput2'

const formatDate = date => tz.format(date, 'date.formats.medium')

function renderInput(overrides = {}) {
  const props = {
    selectedDate: null,
    renderLabel: () => 'label',
    messages: [],
    timezone: 'UTC',
    formatDate: jest.fn(formatDate),
    onSelectedDateChange: jest.fn(),
    ...overrides,
  }
  const result = render(<CanvasDateInput2 {...props} />)
  result.props = props
  result.getInput = () => result.getByLabelText(new RegExp(props.renderLabel()))
  return result
}

function renderAndDirtyInput(inputValue, overrides = {}) {
  const result = renderInput(overrides)
  const input = result.getInput()
  fireEvent.change(input, {target: {value: inputValue}})
  return result
}

function pressKey(inputElem, keyOpts) {
  fireEvent.keyDown(inputElem, keyOpts)
  fireEvent.keyUp(inputElem, keyOpts)
}

const oldLocale = moment.locale()

beforeEach(() => {
  // Not directly at midnight so we can test the dates coming from this component are set to the
  // beginning of the day and don't retain the time.
  MockDate.set('2025-04-09T00:42:00Z', 0)
  moment.locale('en-us')
  jest.useFakeTimers({
    doNotFake: ['Date'],
  })
})

afterEach(() => {
  MockDate.reset()
  jest.useRealTimers()
  moment.locale(oldLocale)
})

describe('clean input state', () => {
  it('displays an empty input value when the selectedDate prop is initially null', () => {
    const {getInput} = renderInput()
    expect(getInput().value).toBe('')
  })

  it('renders placeholder text if provided', () => {
    const {getByPlaceholderText} = renderInput({placeholder: 'some placeholder text'})
    expect(getByPlaceholderText('some placeholder text')).toBeInTheDocument()
  })

  it('renders the message if provided', () => {
    const {getByText} = renderInput({
      messages: [{type: 'hint', text: 'This is the hint'}],
    })
    expect(getByText('This is the hint')).toBeInTheDocument()
  })

  it('renders the invalidDateMessage when the input cannot be parsed', () => {
    const {getByText, getInput} = renderInput({
      invalidDateMessage: 'This is the invalid date message',
    })
    fireEvent.change(getInput(), {target: {value: 'asdf'}})
    expect(getByText('This is the invalid date message')).toBeInTheDocument()
  })

  it('displays the formatted date when the initial date is not null', () => {
    const now = new Date()
    const formatter = jest.fn(() => 'formatted date')
    const {getInput} = renderInput({selectedDate: now, formatDate: formatter})
    expect(formatter).toHaveBeenCalledWith(now)
    expect(getInput().value).toBe('formatted date')
  })

  it('resets the input when the selectedDate changes value', () => {
    const now = moment.tz('UTC')
    const {props, rerender, getInput} = renderInput({selectedDate: now.toDate()})
    props.selectedDate = now.add(1, 'day').toDate()
    rerender(<CanvasDateInput2 {...props} />)
    expect(getInput().value).toBe(formatDate(now))
  })

  it('resets the input when the selectedDate changes from null to a date', () => {
    const now = moment.tz('UTC')
    const {props, rerender, getInput} = renderInput()
    props.selectedDate = now.toDate()
    rerender(<CanvasDateInput2 {...props} />)
    expect(getInput().value).toBe(formatDate(now))
  })

  it('clears the input when the selectedDate changes to null', () => {
    const now = moment.tz('UTC')
    const {props, rerender, getInput} = renderInput({selectedDate: now.toDate()})
    props.selectedDate = null
    rerender(<CanvasDateInput2 {...props} />)
    expect(getInput().value).toBe('')
  })
})

describe('choosing a day on the calendar', () => {
  it('selects the date when clicked', async () => {
    const user = userEvent.setup({
      advanceTimers: jest.advanceTimersByTime,
    })
    const {props, getInput} = renderInput()
    await user.click(getInput())
    await user.tab()
    await user.keyboard('[Space]') // Open the date picker
    const button15 = screen.getByText('15').closest('button')
    await user.click(button15)
    expect(props.onSelectedDateChange).toHaveBeenCalledWith(new Date('2025-04-15'), 'pick')
  })

  it('hides the calendar when clicked', async () => {
    const user = userEvent.setup({
      advanceTimers: jest.advanceTimersByTime,
    })
    const {queryByText, getInput} = renderInput()
    await user.click(getInput())
    await user.tab()
    await user.keyboard('[Space]')
    const button15 = screen.getByText('15').closest('button')
    await user.click(button15)
    expect(queryByText('15')).toBeNull()
  })
})

describe('dirty input state', () => {
  it('clears the input when blurred with invalid input', () => {
    const {getInput} = renderAndDirtyInput('asdf')
    fireEvent.blur(getInput())
    expect(getInput().value).toBe('')
  })

  it('resets the input when selectedDate changes to a new date', () => {
    const {props, rerender, getInput} = renderAndDirtyInput('asdf')
    expect(getInput().value).toBe('asdf')
    const newDate = new Date()
    props.selectedDate = new Date()
    rerender(<CanvasDateInput2 {...props} />)
    expect(getInput().value).toBe(formatDate(newDate))
  })

  it('resets the input when the selectedDate changes to null', () => {
    const {props, rerender, getInput} = renderAndDirtyInput('asdf', {selectedDate: new Date()})
    expect(getInput().value).toBe('asdf')
    props.selectedDate = null
    rerender(<CanvasDateInput2 {...props} />)
    expect(getInput().value).toBe('')
  })

  it('calls onSelectedDateChange with parsed date when the input blurs and sets the date input', () => {
    const {props, getInput} = renderAndDirtyInput('Apr 10')
    const newDate = new Date('2025-04-10')
    fireEvent.blur(getInput())
    expect(props.onSelectedDateChange).toHaveBeenCalledWith(newDate, 'other')
    expect(getInput().value).toBe(formatDate(newDate))
  })

  it('calls onSelectedDateChange with parsed date when Enter is pressed on the input', () => {
    const {props, getInput} = renderAndDirtyInput('Apr 10')
    const newDate = new Date('2025-04-10')
    pressKey(getInput(), {key: 'Enter'})
    expect(props.onSelectedDateChange).toHaveBeenCalledWith(newDate, 'other')
  })

  it('calls onSelectedDateChange with on blur and garbage input, and clears the input', () => {
    const {props, getInput} = renderAndDirtyInput('asdf')
    fireEvent.blur(getInput())
    expect(props.onSelectedDateChange).toHaveBeenCalledWith(null, 'other')
    expect(getInput().value).toBe('')
  })

  it('handles the date in the given timezone', () => {
    const tz = 'Pacific/Tarawa' // +12
    const handleDateChange = jest.fn()
    const {getInput} = renderAndDirtyInput('Apr 10, 2025', {
      selectedDate: new Date(),
      timezone: tz,
      onSelectedDateChange: handleDateChange,
    })
    fireEvent.blur(getInput())
    expect(handleDateChange.mock.calls[0][0].toISOString()).toEqual('2025-04-10T00:00:00.000Z')
  })
})

describe('error messages', () => {
  it('shows an error message if the input date is unparseable', () => {
    const {getByText} = renderAndDirtyInput('asdf')
    expect(getByText('Invalid date format')).toBeInTheDocument()
  })

  it('clears error messages when the selectedDate changes', () => {
    const {props, rerender, queryByText} = renderAndDirtyInput('asdf')
    props.selectedDate = new Date()
    rerender(<CanvasDateInput2 {...props} />)
    expect(queryByText('Invalid Date')).toBeNull()
  })

  it('clears error messages when the input changes to an empty string', () => {
    const {getInput, queryByText} = renderAndDirtyInput('asdf')
    fireEvent.change(getInput(), {target: {value: ''}})
    expect(queryByText('Invalid Date')).toBeNull()
  })
})

describe('messages', () => {
  it('shows the specified messages', () => {
    const {getByText} = renderInput({
      messages: [{type: 'hint', text: 'my what an interesting date'}],
    })
    expect(getByText('my what an interesting date')).toBeInTheDocument()
  })

  it('shows a running result when requested', () => {
    const {getByText} = renderAndDirtyInput('sat', {withRunningValue: true})
    // The Saturday after our "current date" is 4/12/2025
    expect(getByText('Apr 12, 2025')).toBeInTheDocument()
  })
})

describe('disabled dates', () => {
  it('renders disabled dates as disabled', async () => {
    const user = userEvent.setup({
      advanceTimers: jest.advanceTimersByTime,
    })
    const {getInput} = renderInput({disabledDates: () => true})
    await user.click(getInput())
    await user.tab()
    await user.keyboard('[Space]') // Open the date picker
    const button12 = screen.getByText('12').closest('button')
    const button22 = screen.getByText('22').closest('button')
    ;[button12, button22].forEach(b => expect(b).toBeDisabled())
  })

  it('does not select a disabled date when clicked', async () => {
    const user = userEvent.setup({
      advanceTimers: jest.advanceTimersByTime,
    })
    const {props, getInput} = renderInput({disabledDates: () => true})
    await user.click(getInput())
    await user.tab()
    await user.keyboard('[Space]')
    const button15 = screen.getByText('15').closest('button')
    await user.click(button15)
    expect(props.onSelectedDateChange).not.toHaveBeenCalledWith(new Date('2025-04-15'))
  })
})

describe('with defaultToToday set to true', () => {
  it('defaults to today when the input is empty', () => {
    const today = new Date()
    const {getInput} = renderInput({defaultToToday: true})
    fireEvent.click(getInput())
    expect(getInput().value).toBe('')
    fireEvent.blur(getInput())
    expect(getInput().value).toBe(formatDate(today))
  })

  it('leaves invalid input in place', () => {
    const {getByText, getInput} = renderInput({
      defaultToToday: true,
      messages: [{type: 'hint', text: 'This is the hint'}],
    })
    fireEvent.change(getInput(), {target: {value: 'asdf'}})
    fireEvent.blur(getInput())
    expect(getInput().value).toBe('asdf')
    expect(getByText('Invalid date format')).toBeInTheDocument()
    expect(getByText('This is the hint')).toBeInTheDocument()
  })
})
