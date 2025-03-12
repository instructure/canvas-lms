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
import {render, screen} from '@testing-library/react'
import CourseActivityDetails, {type CourseActivityDetailsProps} from '../CourseActivityDetails'
import {dateString, timeString} from '@canvas/datetime/date-functions'

describe('CourseActivityDetails', () => {
  const props: CourseActivityDetailsProps = {
    id: '153ee9e4-3978-443b-a3e2-7bad9c1ddd89',
    created_at: '2024-01-01T00:00:00Z',
    event_source_present: 'Manual',
    event_type_present: 'Created',
    event_source: 'manual',
    event_type: 'created',
    event_data: {},
    user: {
      name: 'mock@user.com',
    },
    onClose: jest.fn(),
  }

  it('should render common fields', () => {
    render(<CourseActivityDetails {...props} />)
    const eventId = screen.getByText(props.id)
    const date = screen.getByText(dateString(props.created_at, {format: 'medium'}))
    const time = screen.getByText(timeString(props.created_at))
    const userName = screen.getByText(props.user?.name ? props.user.name : 'mock@user.com')
    const source = screen.getByText(props.event_source_present)
    const type = screen.getByText(props.event_type_present)

    expect(eventId).toBeInTheDocument()
    expect(date).toBeInTheDocument()
    expect(time).toBeInTheDocument()
    expect(userName).toBeInTheDocument()
    expect(source).toBeInTheDocument()
    expect(type).toBeInTheDocument()
  })

  it.each([
    {eventType: 'copied_from' as const, label: 'Copied From:'},
    {eventType: 'copied_to' as const, label: 'Copied To:'},
    {eventType: 'reset_from' as const, label: 'Reset From:'},
    {eventType: 'reset_to' as const, label: 'Reset To:'},
  ])(
    'should render the correct label and value for event type "$eventType"',
    ({eventType, label}) => {
      const course = {
        id: '123',
        name: 'Mock course',
      }
      const modifiedProps: CourseActivityDetailsProps = {
        ...props,
        event_type: eventType,
        [eventType]: course,
        event_data: undefined,
      }
      render(<CourseActivityDetails {...modifiedProps} />)
      const copiedToLabel = screen.getByText(label)
      const copiedToValue = screen.getByText(course.name)

      expect(copiedToLabel).toBeInTheDocument()
      expect(copiedToValue).toBeInTheDocument()
      expect(copiedToValue).toHaveAttribute('href', `/courses/${course.id}`)
    },
  )

  describe('when the source is SIS', () => {
    it('should render the SIS Batch information', () => {
      const sis_batch_id = '5'
      const modifiedProps: CourseActivityDetailsProps = {
        ...props,
        event_source: 'sis',
        links: {sis_batch: sis_batch_id},
      }
      render(<CourseActivityDetails {...modifiedProps} />)
      const sisBatchLabel = screen.getByText('SIS Batch:')
      const sisBatchValue = screen.getByText(sis_batch_id)

      expect(sisBatchLabel).toBeInTheDocument()
      expect(sisBatchValue).toBeInTheDocument()
    })
  })

  it('should render the table correctly for event type "created"', () => {
    const modifiedProps: CourseActivityDetailsProps = {
      ...props,
      event_type: 'created',
      event_data: {
        Name: 'Mock name',
        'Account Id': '123',
        License: 'private',
      },
    }
    render(<CourseActivityDetails {...modifiedProps} />)
    const fieldHeader = screen.getByText('Field')
    const valueHeader = screen.getByText('Value')

    expect(fieldHeader).toBeInTheDocument()
    expect(valueHeader).toBeInTheDocument()
    Object.entries(modifiedProps.event_data).forEach(([key, value]) => {
      expect(screen.getByText(key)).toBeInTheDocument()
      expect(screen.getByText(value)).toBeInTheDocument()
    })
  })

  it('should render the table correctly for event type "updated"', () => {
    const modifiedProps: CourseActivityDetailsProps = {
      ...props,
      event_type: 'updated',
      event_data: {
        Name: {from: 'Old name', to: 'New name'},
        'Account Id': {from: '123', to: '456'},
        License: {from: 'private', to: 'public'},
      },
    }
    render(<CourseActivityDetails {...modifiedProps} />)
    const fieldHeader = screen.getByText('Field')
    const fromHeader = screen.getByText('From')
    const toHeader = screen.getByText('To')

    expect(fieldHeader).toBeInTheDocument()
    expect(fromHeader).toBeInTheDocument()
    expect(toHeader).toBeInTheDocument()
    Object.entries(modifiedProps.event_data).forEach(([key, {from, to}]) => {
      expect(screen.getByText(key)).toBeInTheDocument()
      expect(screen.getByText(from)).toBeInTheDocument()
      expect(screen.getByText(to)).toBeInTheDocument()
    })
  })

  it('should render the table even if user is missing', () => {
    render(<CourseActivityDetails {...props} user={undefined} />)
    const eventId = screen.getByText(props.id)
    const date = screen.getByText(dateString(props.created_at, {format: 'medium'}))
    const time = screen.getByText(timeString(props.created_at))
    const userName = screen.getByText('-')
    const source = screen.getByText(props.event_source_present)
    const type = screen.getByText(props.event_type_present)

    expect(eventId).toBeInTheDocument()
    expect(date).toBeInTheDocument()
    expect(time).toBeInTheDocument()
    expect(userName).toBeInTheDocument()
    expect(source).toBeInTheDocument()
    expect(type).toBeInTheDocument()
  })
})
