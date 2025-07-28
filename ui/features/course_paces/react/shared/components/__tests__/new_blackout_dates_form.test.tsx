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
import moment from 'moment-timezone'
import {act, fireEvent, render} from '@testing-library/react'

import NewBlackoutDatesForm from '../new_blackout_dates_form'

const addBlackoutDate = jest.fn()

describe('BlackoutDatesModal', () => {
  beforeAll(() => {
    window.ENV.TIMEZONE = 'America/Denver'
    window.ENV.CONTEXT_TIMEZONE = 'America/Denver'
    moment.tz.setDefault('America/Denver')
  })

  afterEach(() => {
    jest.resetAllMocks()
  })

  it('renders', () => {
    const {getByRole, getByText} = render(
      <NewBlackoutDatesForm addBlackoutDate={addBlackoutDate} />,
    )

    expect(getByRole('textbox', {name: 'Event Title'})).toBeInTheDocument()
    expect(getByText('Start Date')).toBeInTheDocument()
    expect(getByText('End Date')).toBeInTheDocument()
    const addBtn = getByRole('button', {name: 'Add'})
    expect(addBtn).toBeInTheDocument()
    act(() => addBtn.click())
    expect(addBlackoutDate).not.toHaveBeenCalled()
  })

  it('shows error message for missing event title', () => {
    const {getByRole, getByText, queryByText} = render(
      <NewBlackoutDatesForm addBlackoutDate={addBlackoutDate} />,
    )
    expect(queryByText('Title required')).not.toBeInTheDocument()

    const titleInput = getByRole('textbox', {name: 'Event Title'})
    const addBtn = getByRole('button', {name: 'Add'})

    act(() => titleInput.focus())
    act(() => addBtn.focus())

    expect(getByText('Title required')).toBeInTheDocument()
    act(() => addBtn.click())
    expect(addBlackoutDate).not.toHaveBeenCalled()
  })

  it('shows error message for missing start date', () => {
    const {getByRole, getByText, queryByText} = render(
      <NewBlackoutDatesForm addBlackoutDate={addBlackoutDate} />,
    )
    expect(queryByText('Date required')).not.toBeInTheDocument()

    const dateInput = getByText('Start Date')
    const addBtn = getByRole('button', {name: 'Add'})
    act(() => dateInput.focus())
    act(() => addBtn.focus())

    expect(getByText('Date required')).toBeInTheDocument()
    act(() => addBtn.click())
    expect(addBlackoutDate).not.toHaveBeenCalled()
  })

  it('shows error message for missing start date when end date blurs', () => {
    const {getByRole, getByText, queryByText} = render(
      <NewBlackoutDatesForm addBlackoutDate={addBlackoutDate} />,
    )
    expect(queryByText('Date required')).not.toBeInTheDocument()

    const dateInput = getByText('End Date')
    const addBtn = getByRole('button', {name: 'Add'})
    act(() => dateInput.focus())
    act(() => addBtn.focus())

    expect(getByText('Date required')).toBeInTheDocument()
    act(() => addBtn.click())
    expect(addBlackoutDate).not.toHaveBeenCalled()
  })

  it('shows error message when end date is before start date', () => {
    const {getByRole, getByTestId, queryByText} = render(
      <NewBlackoutDatesForm addBlackoutDate={addBlackoutDate} />,
    )
    expect(queryByText('End date cannot be before start date')).not.toBeInTheDocument()

    const startDateInput = getByTestId('new-blackout-dates-start')
    const endDateInput = getByTestId('new-blackout-dates-end')
    const addBtn = getByRole('button', {name: 'Add'})
    act(() => startDateInput.focus())
    act(() => {
      fireEvent.change(startDateInput, {target: {value: 'April 15, 2022'}})
    })
    act(() => endDateInput.focus())
    act(() => {
      fireEvent.change(endDateInput, {target: {value: 'April 1, 2022'}})
    })
    act(() => addBtn.focus())

    expect(queryByText('End date cannot be before start date')).toBeInTheDocument()
    act(() => addBtn.click())
    expect(addBlackoutDate).not.toHaveBeenCalled()
  })

  it('shows title and start date errors when fields are empty and Add button gets focus', () => {
    const {getByRole, getByText, queryByText} = render(
      <NewBlackoutDatesForm addBlackoutDate={addBlackoutDate} />,
    )
    expect(queryByText('Title required')).not.toBeInTheDocument()
    expect(queryByText('Date required')).not.toBeInTheDocument()

    const addBtn = getByRole('button', {name: 'Add'})
    act(() => addBtn.focus())

    expect(getByText('Title required')).toBeInTheDocument()
    expect(getByText('Date required')).toBeInTheDocument()
    act(() => addBtn.click())
    expect(addBlackoutDate).not.toHaveBeenCalled()
  })

  it('enables Add when data is provided', () => {
    const {getByRole, getByTestId} = render(
      <NewBlackoutDatesForm addBlackoutDate={addBlackoutDate} />,
    )
    const titleInput = getByRole('textbox', {name: 'Event Title'})
    const startDateInput = getByTestId('new-blackout-dates-start')
    const addBtn = getByRole('button', {name: 'Add'})
    act(() => titleInput.focus())
    act(() => {
      fireEvent.change(titleInput, {target: {value: 'blackout title'}})
    })
    act(() => startDateInput.focus())
    act(() => {
      fireEvent.change(startDateInput, {target: {value: 'April 15, 2022'}})
    })
    act(() => addBtn.focus())
    act(() => addBtn.click())
    expect(addBlackoutDate).toHaveBeenCalled() // yay!
  })
})
