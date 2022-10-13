/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {act, fireEvent, render, within} from '@testing-library/react'

import {BLACKOUT_DATES} from '../../../__tests__/fixtures'
import BlackoutDates from '../blackout_dates'

const onChange = jest.fn()

const defaultProps = {
  blackoutDates: BLACKOUT_DATES,
  onChange,
}

describe('BlackoutDates', () => {
  afterEach(() => {
    jest.resetAllMocks()
  })

  it('renders', () => {
    const {getByTestId} = render(<BlackoutDates {...defaultProps} />)
    expect(getByTestId('new_blackout_dates_form')).toBeInTheDocument()
    const blackoutTable = getByTestId('blackout_dates_table')
    expect(blackoutTable).toBeInTheDocument()

    expect(blackoutTable.querySelectorAll('tr').length).toBe(2)
    const newBlackoutDatesRow = blackoutTable.querySelectorAll('tr')[1]
    expect(within(newBlackoutDatesRow).getByText('Spring break')).toBeInTheDocument()
    expect(within(newBlackoutDatesRow).getByText('Mon, Mar 21, 2022')).toBeInTheDocument()
    expect(within(newBlackoutDatesRow).getByText('Fri, Mar 25, 2022')).toBeInTheDocument()
  })

  it('shows "No blackout dates" if there are none', () => {
    const {getByTestId} = render(<BlackoutDates blackoutDates={[]} onChange={() => {}} />)
    expect(getByTestId('new_blackout_dates_form')).toBeInTheDocument()
    const blackoutTable = getByTestId('blackout_dates_table')
    expect(blackoutTable).toBeInTheDocument()

    expect(blackoutTable.querySelectorAll('tr').length).toBe(2)
    const newBlackoutDatesRow = blackoutTable.querySelectorAll('tr')[1]
    expect(within(newBlackoutDatesRow).getByText('No blackout dates')).toBeInTheDocument()
  })

  it('adds new blackout dates', () => {
    const newBlackoutDate = {
      event_title: 'Black me out',
      start_date: 'April 1, 2022',
      end_date: 'April 2, 2022',
    }
    const {getByLabelText, getByRole} = render(<BlackoutDates {...defaultProps} />)

    const eventTitle = getByLabelText('Event Title')
    const startDate = getByLabelText('Start Date')
    const endDate = getByLabelText('End Date')
    const addBtn = getByRole('button', {name: 'Add'})

    act(() => {
      fireEvent.change(eventTitle, {target: {value: newBlackoutDate.event_title}})
    })
    act(() => {
      fireEvent.change(startDate, {
        target: {value: newBlackoutDate.start_date},
      })
    })
    act(() => {
      fireEvent.blur(startDate)
    })
    act(() => {
      fireEvent.change(endDate, {target: {value: newBlackoutDate.end_date}})
    })
    act(() => {
      fireEvent.blur(endDate)
    })
    act(() => {
      addBtn.click()
    })
    expect(onChange).toHaveBeenCalled()
    expect(onChange.mock.calls[0][0].length).toBe(2)
  })

  it('deletes a blackout date', () => {
    const {getByRole} = render(<BlackoutDates {...defaultProps} />)

    const delBtn = getByRole('button', {name: 'Delete blackout date Spring break'})

    act(() => delBtn.click())
    expect(onChange).toHaveBeenCalled()
    expect(onChange.mock.calls[0][0].length).toBe(0)
  })
})
