/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import MockDate from 'mockdate'
import moment from 'moment-timezone'
import CanvasDateInput from '../DateInput'

function renderInput(overrides = {}) {
  const props = {
    selectedDate: null,
    renderLabel: () => 'label',
    messages: [],
    timezone: 'UTC',
    formatDate: jest.fn(date => date.toISOString()),
    onSelectedDateChange: jest.fn(),
    ...overrides,
  }
  const result = render(<CanvasDateInput {...props} />)
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
  MockDate.set('2020-05-19T00:42:00Z', 0)
  moment.locale('en-us')
})

afterEach(() => {
  MockDate.reset()
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
    rerender(<CanvasDateInput {...props} />)
    expect(getInput().value).toBe(now.toISOString())
  })

  it('resets the input when the selectedDate changes from null to a date', () => {
    const now = moment.tz('UTC')
    const {props, rerender, getInput} = renderInput()
    props.selectedDate = now.toDate()
    rerender(<CanvasDateInput {...props} />)
    expect(getInput().value).toBe(now.toISOString())
  })

  it('clears the input when the selectedDate changes to null', () => {
    const now = moment.tz('UTC')
    const {props, rerender, getInput} = renderInput({selectedDate: now.toDate()})
    props.selectedDate = null
    rerender(<CanvasDateInput {...props} />)
    expect(getInput().value).toBe('')
  })
})

describe('choosing a day on the calendar', () => {
  it('selects the date when clicked', () => {
    const {props, getByText, getInput} = renderInput()
    fireEvent.click(getInput())
    const button15 = getByText('15').closest('button')
    fireEvent.click(button15)
    expect(props.onSelectedDateChange).toHaveBeenCalledWith(new Date('2020-05-15'), 'pick')
  })

  it('hides the calendar when clicked', () => {
    const {getByText, queryByText, getInput} = renderInput()
    fireEvent.click(getInput())
    const button15 = getByText('15').closest('button')
    fireEvent.click(button15)
    expect(queryByText('15')).toBeNull()
  })

  it('selects the first of the month on ArrowDown if selectedDate is null', () => {
    const {props, getInput} = renderInput()
    fireEvent.click(getInput())
    pressKey(getInput(), {key: 'ArrowDown', code: 40, keyCode: 40})
    expect(props.onSelectedDateChange).toHaveBeenCalledWith(new Date('2020-05-01'), 'pick')
  })

  it('selects the first of the month on up-arrow if selectedDate is null', () => {
    const {props, getInput} = renderInput()
    fireEvent.click(getInput())
    pressKey(getInput(), {key: 'ArrowUp', code: 38, keyCode: 38})
    expect(props.onSelectedDateChange).toHaveBeenCalledWith(new Date('2020-05-01'), 'pick')
  })

  it('selects the next date on down-arrow', () => {
    const {props, getInput} = renderInput({selectedDate: new Date()})
    fireEvent.click(getInput())
    pressKey(getInput(), {key: 'ArrowDown', code: 40, keyCode: 40})
    expect(props.onSelectedDateChange).toHaveBeenCalledWith(new Date('2020-05-20'), 'pick')
  })

  it('selects the previous date on up-arrow', () => {
    const {props, getInput} = renderInput({selectedDate: new Date()})
    fireEvent.click(getInput())
    pressKey(getInput(), {key: 'ArrowUp', code: 38, keyCode: 38})
    expect(props.onSelectedDateChange).toHaveBeenCalledWith(new Date('2020-05-18'), 'pick')
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
    rerender(<CanvasDateInput {...props} />)
    expect(getInput().value).toBe(newDate.toISOString())
  })

  it('resets the input when the selectedDate changes to null', () => {
    const {props, rerender, getInput} = renderAndDirtyInput('asdf', {selectedDate: new Date()})
    expect(getInput().value).toBe('asdf')
    props.selectedDate = null
    rerender(<CanvasDateInput {...props} />)
    expect(getInput().value).toBe('')
  })

  it('calls onSelectedDateChange with parsed date when the input blurs and sets the date input', () => {
    const {props, getInput} = renderAndDirtyInput('May 20')
    const newDate = new Date('2020-05-20')
    fireEvent.blur(getInput())
    expect(props.onSelectedDateChange).toHaveBeenCalledWith(newDate, 'other')
    expect(getInput().value).toBe(newDate.toISOString())
  })

  it('calls onSelectedDateChange with parsed date when Enter is pressed on the input', () => {
    const {props, getInput} = renderAndDirtyInput('May 20')
    const newDate = new Date('2020-05-20')
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
    const {getInput} = renderAndDirtyInput('May 20, 2020', {
      selectedDate: new Date(),
      timezone: tz,
      onSelectedDateChange: handleDateChange,
    })
    fireEvent.blur(getInput())
    expect(handleDateChange.mock.calls[0][0].toISOString()).toEqual('2020-05-20T00:00:00.000Z')
  })
})

describe('rendered month', () => {
  it('renders the proper 42 days based on the rendered month', () => {
    const {getAllByText, getInput} = renderInput()
    fireEvent.click(getInput())
    expect(getAllByText('25')).toHaveLength(1)
    expect(getAllByText('26')).toHaveLength(2)
    expect(getAllByText('6')).toHaveLength(2)
    expect(getAllByText('7')).toHaveLength(1)
  })

  it('renders the month for today when selectedDate is initially null', () => {
    const {getByText, getInput} = renderInput()
    fireEvent.click(getInput())
    expect(getByText('May')).toBeInTheDocument()
  })

  it('renders the month for the initial selectedDate', () => {
    const {getByText, getInput} = renderInput({selectedDate: new Date('2020-03-15')})
    fireEvent.click(getInput())
    expect(getByText('March')).toBeInTheDocument()
  })

  it('allows the rendered month to be incremented', () => {
    const {getByText, getInput} = renderInput()
    fireEvent.click(getInput())
    fireEvent.click(getByText('Next month'))
    expect(getByText('June')).toBeInTheDocument()
  })

  it('allows the rendered month to be decremented', () => {
    const {getByText, getInput} = renderInput()
    fireEvent.click(getInput())
    fireEvent.click(getByText('Previous month'))
    expect(getByText('April')).toBeInTheDocument()
  })

  it('resets the rendered date to the selectedDate when the selectedDate changes', () => {
    const {getByText, getInput} = renderInput()
    fireEvent.click(getInput())
    fireEvent.click(getByText('Next month'))
    fireEvent.change(getInput(), {target: {value: 'April 20'}})
    expect(getByText('April')).toBeInTheDocument()
  })
})

describe('error messages', () => {
  it('shows an error message if the input date is unparseable', () => {
    const {getByText} = renderAndDirtyInput('asdf')
    expect(getByText('Invalid Date')).toBeInTheDocument()
  })

  it('clears error messages when the selectedDate changes', () => {
    const {props, rerender, queryByText} = renderAndDirtyInput('asdf')
    props.selectedDate = new Date()
    rerender(<CanvasDateInput {...props} />)
    expect(queryByText('Invalid Date')).toBeNull()
  })

  it('clears error messages when a day is clicked', () => {
    const date = new Date()
    const {getByText, queryByText} = renderAndDirtyInput('asdf', {selectedDate: date})
    fireEvent.click(getByText('15'))
    expect(queryByText('Invalid Date')).toBeNull()
  })

  it('clears error messages even when selectedDay is clicked', () => {
    const date = new Date()
    const {getByText, queryByText} = renderAndDirtyInput('asdf', {selectedDate: date})
    fireEvent.click(getByText('20'))
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
    // The Saturday after our "current date" is 5/23/2020
    expect(getByText('2020-05-23T00:00:00.000Z')).toBeInTheDocument()
  })
})

describe('disabled dates', () => {
  it('renders disabled dates as disabled', () => {
    const {getByText, getInput} = renderInput({dateIsDisabled: () => true})
    fireEvent.click(getInput())
    const button12 = getByText('12').closest('button')
    const button22 = getByText('22').closest('button')

    ;[button12, button22].forEach(b => expect(b).toBeDisabled())
  })

  it('does not select a disabled date when clicked', () => {
    const {props, getByText, getInput} = renderInput({dateIsDisabled: () => true})
    fireEvent.click(getInput())
    const button15 = getByText('15').closest('button')
    fireEvent.click(button15)
    expect(props.onSelectedDateChange).not.toHaveBeenCalledWith(new Date('2020-05-15'))
  })
})

describe('locales', () => {
  it('renders the month string according to the locale', () => {
    moment.locale('fr')
    const {getByText, getInput} = renderInput({selectedDate: new Date()})
    fireEvent.click(getInput())
    expect(getByText('mai')).toBeInTheDocument()
  })

  it('renders Sunday as the first day of the week in the american locale', () => {
    const {getByText, getInput} = renderInput({selectedDate: new Date()})
    fireEvent.click(getInput())
    const sunday = getByText('Su')
    const headerRow = sunday.closest('tr')
    const sundayHeader = sunday.closest('th')
    expect(headerRow.children[0]).toBe(sundayHeader)
  })

  it('renders Monday as the first day of the week in french locale', () => {
    moment.locale('fr')
    const {getByText, getInput} = renderInput({selectedDate: new Date()})
    fireEvent.click(getInput())
    const lundi = getByText('lu')
    const headerRow = lundi.closest('tr')
    const lundiHeader = lundi.closest('th')
    expect(headerRow.children[0]).toBe(lundiHeader)
  })
})

describe('with defaultToToday set to true', () => {
  it('defaults to today when the input is empty', () => {
    const today = new Date()
    const {getInput} = renderInput({defaultToToday: true})
    fireEvent.click(getInput())
    expect(getInput().value).toBe('')
    fireEvent.blur(getInput())
    expect(getInput().value).toBe(today.toISOString())
  })

  it('leaves invalid input in place', () => {
    const {getByText, getInput} = renderInput({
      defaultToToday: true,
      messages: [{type: 'hint', text: 'This is the hint'}],
    })
    fireEvent.change(getInput(), {target: {value: 'asdf'}})
    fireEvent.blur(getInput())
    expect(getInput().value).toBe('asdf')
    expect(getByText('Invalid Date')).toBeInTheDocument()
    expect(getByText('This is the hint')).toBeInTheDocument()
  })
})
