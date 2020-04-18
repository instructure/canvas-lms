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
import CanvasDateInput from '../CanvasDateInput'

function renderInput(overrides = {}) {
  const props = {
    selectedDate: null,
    renderLabel: () => 'label',
    messages: [],
    timezone: 'UTC',
    formatDate: jest.fn(date => date.toISOString()),
    onSelectedDateChange: jest.fn(),
    ...overrides
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

const oldLocale = moment.locale()

beforeEach(() => {
  // A thursday, not directly at midnight so we can test the dates coming from this component are
  // set to the beginning of the day and don't retain the time.
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
    expect(props.onSelectedDateChange).toHaveBeenCalledWith(new Date('2020-05-15'))
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
    fireEvent.keyDown(getInput(), {key: 'ArrowDown', code: 40, keyCode: 40})
    expect(props.onSelectedDateChange).toHaveBeenCalledWith(new Date('2020-05-01'))
  })

  it('selects the first of the month on up-arrow if selectedDate is null', () => {
    const {props, getInput} = renderInput()
    fireEvent.click(getInput())
    fireEvent.keyDown(getInput(), {key: 'ArrowUp', code: 38, keyCode: 38})
    expect(props.onSelectedDateChange).toHaveBeenCalledWith(new Date('2020-05-01'))
  })

  it('selects the next date on down-arrow', () => {
    const {props, getInput} = renderInput({selectedDate: new Date()})
    fireEvent.click(getInput())
    fireEvent.keyDown(getInput(), {key: 'ArrowDown', code: 40, keyCode: 40})
    expect(props.onSelectedDateChange).toHaveBeenCalledWith(new Date('2020-05-20'))
  })

  it('selects the previous date on up-arrow', () => {
    const {props, getInput} = renderInput({selectedDate: new Date()})
    fireEvent.click(getInput())
    fireEvent.keyDown(getInput(), {key: 'ArrowUp', code: 38, keyCode: 38})
    expect(props.onSelectedDateChange).toHaveBeenCalledWith(new Date('2020-05-18'))
  })
})

describe('typing a date into the input', () => {
  it('changes the date when the input is parseable', () => {})
  it('sets selected date to null when input is not parseable', () => {})
  it('changes the rendered month when the input is parseable', () => {})
})

describe('dirty input state', () => {
  it('keeps the input when the selectedDate changes value', () => {
    const {props, rerender, getInput} = renderAndDirtyInput('asdf')
    props.selectedDate = new Date()
    rerender(<CanvasDateInput {...props} />)
    expect(getInput().value).toBe('asdf')
  })

  it('keeps the input when the selectedDate changes to null', () => {
    const {props, rerender, getInput} = renderAndDirtyInput('asdf', {selectedDate: new Date()})
    props.selectedDate = null
    rerender(<CanvasDateInput {...props} />)
    expect(getInput().value).toBe('asdf')
  })

  it('keeps the input when the selectedDate changes to non-null', () => {
    const {props, rerender, getInput} = renderAndDirtyInput('asdf')
    props.selectedDate = new Date()
    rerender(<CanvasDateInput {...props} />)
    expect(getInput().value).toBe('asdf')
  })

  it('resets the input when a date is selected from the calendar, even when dirty', () => {
    const {getByText, getInput} = renderAndDirtyInput('asdf')
    expect(getInput().value).toBe('asdf')
    fireEvent.click(getByText('15').closest('button'))
    expect(getInput().value).toBe(new Date('2020-05-15').toISOString())
  })

  it('resets the dirty input when the input blurs', () => {
    const {props, rerender, getInput} = renderAndDirtyInput('friday') // default date is Thursday
    // parsed date gets reported, need to rerender with that
    props.selectedDate = props.onSelectedDateChange.mock.calls[0][0]
    rerender(<CanvasDateInput {...props} />)
    fireEvent.blur(getInput())
    expect(getInput().value).toBe(new Date('2020-05-22').toISOString())
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
    fireEvent.change(getInput(), {target: {value: 'friday'}})
    expect(getByText('May')).toBeInTheDocument()
  })
})

describe('error messages', () => {
  it('shows an error message if the input date is unparseable and the input blurs', () => {
    const {getByText, getInput} = renderAndDirtyInput('asdf')
    fireEvent.blur(getInput())
    expect(getByText("That's not a date!")).toBeInTheDocument()
  })

  it('shows an error message if the input date is unparseable and the calendar closes', () => {
    const {getByText, getInput} = renderAndDirtyInput('asdf')
    // Yes, this has to be keyUp. _sigh_
    fireEvent.keyUp(getInput(), {key: 'Escape', code: 27, keyCode: 27})
    expect(getByText("That's not a date!")).toBeInTheDocument()
  })
})

describe('messages', () => {
  it('shows the specified messages', () => {
    const {getByText} = renderInput({
      messages: [{type: 'hint', text: 'my what an interesting date'}]
    })
    expect(getByText('my what an interesting date')).toBeInTheDocument()
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
