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
import {fireEvent, render, screen, waitFor} from '@testing-library/react'
import CourseActivityForm, {type CourseActivityFormProps} from '../CourseActivityForm'
import userEvent from '@testing-library/user-event'

describe('CourseActivityForm', () => {
  const props: CourseActivityFormProps = {
    accountId: '1',
    onSubmit: jest.fn(),
  }

  afterEach(() => jest.resetAllMocks())

  it('should be able to submit the form with course id only', async () => {
    render(<CourseActivityForm {...props} />)
    const courseIdValue = '123'
    const courseId = screen.getByLabelText('Course ID *')
    const submit = screen.getByLabelText('Find')

    fireEvent.change(courseId, {target: {value: courseIdValue}})
    fireEvent.click(submit)

    await waitFor(() => {
      expect(props.onSubmit).toHaveBeenCalledWith({
        course_id: courseIdValue,
        start_time: undefined,
        end_time: undefined,
      })
    })
  })

  it('should be able to submit the form with course id and dates', async () => {
    render(<CourseActivityForm {...props} />)
    const courseIdValue = '123'
    const courseId = screen.getByLabelText('Course ID *')
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

    fireEvent.change(courseId, {target: {value: courseIdValue}})
    fireEvent.input(fromDate, {target: {value: fromDateValue}})
    fireEvent.blur(fromDate)
    fireEvent.input(fromTime, {target: {value: timeValue}})
    fireEvent.blur(fromTime)
    fireEvent.input(toDate, {target: {value: toDateValue}})
    fireEvent.blur(toDate)
    fireEvent.input(toTime, {target: {value: timeValue}})
    fireEvent.blur(toTime)
    await userEvent.click(submit)

    await waitFor(() => {
      expect(props.onSubmit).toHaveBeenCalledWith({
        course_id: courseIdValue,
        start_time: expectedFromDate,
        end_time: expectedToDate,
      })
    })
  })

  it('should show an error if the course id is empty', async () => {
    render(<CourseActivityForm {...props} />)
    const submit = screen.getByLabelText('Find')

    fireEvent.click(submit)

    const errorText = await screen.findByText('Course ID is required.')
    expect(errorText).toBeInTheDocument()
  })

  it('should show an error if date fields are invalid', async () => {
    render(<CourseActivityForm {...props} />)
    const invalidDate = 'invalid date'
    const fromDate = screen.getByLabelText('From Date')
    const toDate = screen.getByLabelText('To Date')
    const submit = screen.getByLabelText('Find')

    fireEvent.input(fromDate, {target: {value: invalidDate}})
    fireEvent.blur(fromDate)
    fireEvent.input(toDate, {target: {value: invalidDate}})
    fireEvent.blur(toDate)
    await userEvent.click(submit)

    const errorText = await screen.findAllByText('Invalid date and time.')
    const visualAndScreenReaderErrorMessagesCount = 2
    expect(errorText).toHaveLength(visualAndScreenReaderErrorMessagesCount)
    expect(props.onSubmit).not.toHaveBeenCalled()
  })

  it('should show an error message if "From" date is after "To" date', async () => {
    render(<CourseActivityForm {...props} />)
    const courseIdValue = '123'
    const courseId = screen.getByLabelText('Course ID *')
    const fromDateValue = 'November 15, 2024'
    const toDateValue = 'November 14, 2024'
    const timeValue = '12:00 AM'
    const fromDate = screen.getByLabelText('From Date')
    const fromTime = screen.getByLabelText('From Time')
    const toDate = screen.getByLabelText('To Date')
    const toTime = screen.getByLabelText('To Time')
    const submit = screen.getByLabelText('Find')

    fireEvent.input(courseId, {target: {value: courseIdValue}})
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
})
