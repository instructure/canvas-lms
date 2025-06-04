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
import {fireEvent, render, screen, waitFor, within} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import UserDateRangeSearch, {type UserDateRangeSearchProps} from '../UserDateRangeSearch'

describe('UserDateRangeSearch', () => {
  const props: UserDateRangeSearchProps = {
    isOpen: true,
    userName: 'John Doe',
    onSubmit: jest.fn(),
    onClose: jest.fn(),
  }

  afterEach(() => jest.resetAllMocks())

  it('should render the user name in the title', async () => {
    render(<UserDateRangeSearch {...props} />)
    const modal = screen.getByLabelText(/generate activity/i)
    const title = within(modal).getByText(`Generate Activity for ${props.userName}`)

    expect(title).toBeInTheDocument()
  })

  it('should be able to submit the empty form', async () => {
    render(<UserDateRangeSearch {...props} />)
    const submit = screen.getByLabelText('Find')

    fireEvent.click(submit)

    await waitFor(() => {
      expect(props.onSubmit).toHaveBeenCalledWith({from: undefined, to: undefined})
    })
  })

  it('should be able to submit the form with "From" date only', async () => {
    render(<UserDateRangeSearch {...props} />)
    const fromDateValue = 'November 14, 2024'
    const fromDate = screen.getByLabelText('From Date')
    const fromTimeValue = '12:00 AM'
    const fromTime = screen.getByLabelText('From Time')
    const submit = screen.getByLabelText('Find')
    const expectedFromDate = new Date(`${fromDateValue}, ${fromTimeValue}`).toISOString()

    await waitFor(() => {
      fireEvent.input(fromDate, {target: {value: fromDateValue}})
    })
    await waitFor(() => {
      fireEvent.blur(fromDate)
    })
    await waitFor(() => {
      fireEvent.input(fromTime, {target: {value: fromTimeValue}})
    })
    await waitFor(() => {
      fireEvent.blur(fromTime)
    })
    await waitFor(() => {
      fireEvent.click(submit)
    })

    await waitFor(() => {
      expect(props.onSubmit).toHaveBeenCalledWith({from: expectedFromDate, to: undefined})
    })
  })

  it('should be able to submit the form with "To" date only', async () => {
    render(<UserDateRangeSearch {...props} />)
    const toDateValue = 'November 14, 2024'
    const toDate = screen.getByLabelText('To Date')
    const toTimeValue = '12:00 AM'
    const toTime = screen.getByLabelText('To Time')
    const submit = screen.getByLabelText('Find')
    const expectedToDate = new Date(`${toDateValue}, ${toTimeValue}`).toISOString()

    await waitFor(() => {
      fireEvent.input(toDate, {target: {value: toDateValue}})
    })
    await waitFor(() => {
      fireEvent.blur(toDate)
    })
    await waitFor(() => {
      fireEvent.input(toTime, {target: {value: toTimeValue}})
    })
    await waitFor(() => {
      fireEvent.blur(toTime)
    })
    await waitFor(() => {
      fireEvent.click(submit)
    })

    await waitFor(() => {
      expect(props.onSubmit).toHaveBeenCalledWith({from: undefined, to: expectedToDate})
    })
  })

  it('should be able to submit the form if "From" date is before "To" date', async () => {
    render(<UserDateRangeSearch {...props} />)
    const fromDateValue = 'November 14, 2024'
    const toDateValue = 'November 15, 2024'
    const fromDate = screen.getByLabelText('From Date')
    const toDate = screen.getByLabelText('To Date')
    const fromTime = screen.getByLabelText('From Time')
    const toTime = screen.getByLabelText('To Time')
    const timeValue = '12:00 AM'
    const submit = screen.getByLabelText('Find')
    const expectedFromDate = new Date(`${fromDateValue}, ${timeValue}`).toISOString()
    const expectedToDate = new Date(`${toDateValue}, ${timeValue}`).toISOString()

    await waitFor(() => {
      fireEvent.input(fromDate, {target: {value: fromDateValue}})
    })
    await waitFor(() => {
      fireEvent.blur(fromDate)
    })
    await waitFor(() => {
      fireEvent.input(fromTime, {target: {value: timeValue}})
    })
    await waitFor(() => {
      fireEvent.blur(fromTime)
    })
    await waitFor(() => {
      fireEvent.input(toDate, {target: {value: toDateValue}})
    })
    await waitFor(() => {
      fireEvent.blur(toDate)
    })
    await waitFor(() => {
      fireEvent.input(toTime, {target: {value: timeValue}})
    })
    await waitFor(() => {
      fireEvent.blur(toTime)
    })
    await waitFor(() => {
      fireEvent.click(submit)
    })

    await waitFor(() => {
      expect(props.onSubmit).toHaveBeenCalledWith({from: expectedFromDate, to: expectedToDate})
    })
  })

  it('should show an error message if "From" date is after "To" date', async () => {
    render(<UserDateRangeSearch {...props} />)
    const fromDateValue = 'November 15, 2024'
    const toDateValue = 'November 14, 2024'
    const timeValue = '12:00 AM'
    const fromDate = screen.getByLabelText('From Date')
    const fromTime = screen.getByLabelText('From Time')
    const toDate = screen.getByLabelText('To Date')
    const toTime = screen.getByLabelText('To Time')
    const submit = screen.getByLabelText('Find')

    fireEvent.input(fromDate, {target: {value: fromDateValue}})
    fireEvent.blur(fromDate)
    fireEvent.input(fromTime, {target: {value: timeValue}})
    fireEvent.blur(fromTime)
    fireEvent.input(toDate, {target: {value: toDateValue}})
    fireEvent.blur(toDate)
    fireEvent.input(toTime, {target: {value: timeValue}})
    fireEvent.blur(toTime)
    await userEvent.click(submit)

    const errorText = await screen.findAllByText('To Date cannot come before From Date.')
    expect(errorText.length).toBeTruthy()
    expect(props.onSubmit).not.toHaveBeenCalled()
  })

  it('should not be able to submit the form if "From" date is invalid', async () => {
    render(<UserDateRangeSearch {...props} />)
    const fromDateValue = 'invalid date'
    const fromDate = screen.getByLabelText('From Date')
    const submit = screen.getByLabelText('Find')

    fireEvent.input(fromDate, {target: {value: fromDateValue}})
    fireEvent.blur(fromDate)
    await userEvent.click(submit)

    const errorText = await screen.findAllByText('Invalid date and time.')
    expect(errorText.length).toBeTruthy()
    expect(props.onSubmit).not.toHaveBeenCalled()
  })

  it('should not be able to submit the form if "To" date is invalid', async () => {
    render(<UserDateRangeSearch {...props} />)
    const toDateValue = 'invalid date'
    const toDate = screen.getByLabelText('To Date')
    const submit = screen.getByLabelText('Find')

    fireEvent.input(toDate, {target: {value: toDateValue}})
    fireEvent.blur(toDate)
    await userEvent.click(submit)

    const errorText = await screen.findAllByText('Invalid date and time.')
    expect(errorText.length).toBeTruthy()
    expect(props.onSubmit).not.toHaveBeenCalled()
  })
})
