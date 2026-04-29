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

// Mock DateTimeInput to make tests more reliable
// The real InstUI DateTimeInput has complex internal state that doesn't respond well to fireEvent
vi.mock('@instructure/ui-date-time-input', () => {
  const React = require('react')
  return {
    DateTimeInput: ({
      dateRenderLabel,
      timeRenderLabel,
      onChange,
      messages,
      invalidDateTimeMessage,
    }: {
      dateRenderLabel: string
      timeRenderLabel: string
      onChange: (event: unknown, isoValue: string | undefined) => void
      messages?: Array<{text: string; type: string}>
      invalidDateTimeMessage?: string
    }) => {
      const [isInvalid, setIsInvalid] = React.useState(false)

      const allMessages = [
        ...(messages || []),
        ...(isInvalid && invalidDateTimeMessage
          ? [{text: invalidDateTimeMessage, type: 'error'}]
          : []),
      ]

      return React.createElement(
        'div',
        null,
        React.createElement('input', {
          'aria-label': dateRenderLabel,
          'data-testid': `${dateRenderLabel.toLowerCase().replace(' ', '-')}-input`,
          onChange: (e: React.ChangeEvent<HTMLInputElement>) => {
            const dateValue = e.target.value
            const invalid = dateValue === 'invalid date'
            setIsInvalid(invalid)
            if (dateValue && !invalid) {
              e.target.setAttribute('data-date-value', dateValue)
            }
            const timeInput = e.target.parentElement?.querySelector(
              `[aria-label="${timeRenderLabel}"]`
            ) as HTMLInputElement
            const timeValue = timeInput?.getAttribute('data-time-value')
            if (dateValue && !invalid && timeValue) {
              onChange(e, new Date(`${dateValue}, ${timeValue}`).toISOString())
            } else if (invalid) {
              onChange(e, undefined)
            }
          },
        }),
        React.createElement('input', {
          'aria-label': timeRenderLabel,
          'data-testid': `${timeRenderLabel.toLowerCase().replace(' ', '-')}-input`,
          onChange: (e: React.ChangeEvent<HTMLInputElement>) => {
            const timeValue = e.target.value
            if (timeValue) {
              e.target.setAttribute('data-time-value', timeValue)
            }
            const dateInput = e.target.parentElement?.querySelector(
              `[aria-label="${dateRenderLabel}"]`
            ) as HTMLInputElement
            const dateValue = dateInput?.getAttribute('data-date-value')
            if (dateValue && timeValue) {
              onChange(e, new Date(`${dateValue}, ${timeValue}`).toISOString())
            }
          },
        }),
        ...allMessages.map((msg, i) =>
          React.createElement('span', {key: i}, msg.text)
        )
      )
    },
  }
})

describe('CourseActivityForm', () => {
  const props: CourseActivityFormProps = {
    accountId: '1',
    onSubmit: vi.fn(),
  }

  afterEach(() => vi.resetAllMocks())

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

    fireEvent.change(courseId, {target: {value: courseIdValue}})
    fireEvent.change(fromDate, {target: {value: fromDateValue}})
    fireEvent.blur(fromDate)
    fireEvent.change(fromTime, {target: {value: timeValue}})
    fireEvent.blur(fromTime)
    fireEvent.change(toDate, {target: {value: toDateValue}})
    fireEvent.blur(toDate)
    fireEvent.change(toTime, {target: {value: timeValue}})
    fireEvent.blur(toTime)
    fireEvent.click(submit)

    await waitFor(() => {
      expect(screen.getAllByText('To Date cannot come before From Date.').length).toBeTruthy()
    })
    expect(props.onSubmit).not.toHaveBeenCalled()
  })
})
