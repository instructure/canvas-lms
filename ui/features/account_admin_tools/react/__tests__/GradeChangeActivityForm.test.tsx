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
import GradeChangeActivityForm, {
  type GradeChangeActivityFormProps,
} from '../GradeChangeActivityForm'
import userEvent from '@testing-library/user-event'

describe('GradeChangeActivityForm', () => {
  const props: GradeChangeActivityFormProps = {
    accountId: '1',
    onSubmit: jest.fn(),
  }

  afterEach(() => jest.resetAllMocks())

  it.each([
    {inputLabel: 'Grader', fieldName: 'grader_id'},
    {inputLabel: 'Student', fieldName: 'student_id'},
    {inputLabel: 'Course', fieldName: 'course_id'},
    {inputLabel: 'Assignment ID', fieldName: 'assignment_id'},
  ])(
    'should be able to submit the form if only "$inputLabel" is provided',
    async ({inputLabel, fieldName}) => {
      render(<GradeChangeActivityForm {...props} />)
      const inputValue = '1'
      const input = screen.getByLabelText(inputLabel)
      const submit = screen.getByLabelText('Search Logs')

      fireEvent.change(input, {target: {value: inputValue}})
      fireEvent.click(submit)

      await waitFor(() => {
        expect(props.onSubmit).toHaveBeenCalledWith({
          grader_id: '',
          student_id: '',
          course_id: '',
          assignment_id: '',
          start_time: undefined,
          end_time: undefined,
          [fieldName]: inputValue,
        })
      })
    },
  )

  it.each([
    {inputLabel: 'Grader', fieldName: 'grader_id'},
    {inputLabel: 'Student', fieldName: 'student_id'},
    {inputLabel: 'Course', fieldName: 'course_id'},
    {inputLabel: 'Assignment ID', fieldName: 'assignment_id'},
  ])(
    'should be able to submit the form with "$inputLabel" and dates',
    async ({inputLabel, fieldName}) => {
      render(<GradeChangeActivityForm {...props} />)
      const inputValue = '1'
      const input = screen.getByLabelText(inputLabel)
      const fromDateValue = 'November 14, 2024'
      const toDateValue = 'November 15, 2024'
      const fromDate = screen.getByLabelText('From Date')
      const toDate = screen.getByLabelText('To Date')
      const fromTime = screen.getByLabelText('From Time')
      const toTime = screen.getByLabelText('To Time')
      const timeValue = '12:00 AM'
      const expectedFromDate = new Date(`${fromDateValue}, ${timeValue}`).toISOString()
      const expectedToDate = new Date(`${toDateValue}, ${timeValue}`).toISOString()
      const submit = screen.getByLabelText('Search Logs')

      fireEvent.change(input, {target: {value: inputValue}})
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
          grader_id: '',
          student_id: '',
          course_id: '',
          assignment_id: '',
          start_time: expectedFromDate,
          end_time: expectedToDate,
          [fieldName]: inputValue,
        })
      })
    },
  )

  it('should show an error if the form is empty', async () => {
    render(<GradeChangeActivityForm {...props} />)
    const submit = screen.getByLabelText('Search Logs')

    fireEvent.click(submit)

    const errorText = await screen.findAllByText('Please enter at least one field.')
    expect(errorText).toBeTruthy()
  })

  it('should show an error if date fields are invalid', async () => {
    render(<GradeChangeActivityForm {...props} />)
    const invalidDate = 'invalid date'
    const fromDate = screen.getByLabelText('From Date')
    const toDate = screen.getByLabelText('To Date')
    const submit = screen.getByLabelText('Search Logs')

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
    render(<GradeChangeActivityForm {...props} />)
    const courseIdValue = '123'
    const courseId = screen.getByLabelText('Course')
    const fromDateValue = 'November 15, 2024'
    const toDateValue = 'November 14, 2024'
    const timeValue = '12:00 AM'
    const fromDate = screen.getByLabelText('From Date')
    const fromTime = screen.getByLabelText('From Time')
    const toDate = screen.getByLabelText('To Date')
    const toTime = screen.getByLabelText('To Time')
    const submit = screen.getByLabelText('Search Logs')

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
