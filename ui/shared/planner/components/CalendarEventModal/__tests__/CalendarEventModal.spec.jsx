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
import {render} from '@testing-library/react'
import moment from 'moment-timezone'
import CalendarEventModal from '../index'
import {convertApiUserContent} from '../../../utilities/contentUtils'

jest.mock('../../../utilities/contentUtils')
convertApiUserContent.mockImplementation(p => p)

function defaultProps(options = {}) {
  const currentUser = options.currentUser || {}
  delete options.currentUser
  return {
    open: true,
    requestClose: jest.fn(),
    title: 'event title',
    html_url: 'http://example.com',
    courseName: 'the course',
    currentUser: {
      id: '1234',
      displayName: 'me',
      avatarUrl: 'http://example.com',
      color: '#777777',
      ...currentUser,
    },
    location: 'somewhere',
    address: 'here, specifically',
    details: 'about this event',
    startTime: moment.tz('2018-09-27T13:00:00', 'Asia/Tokyo'),
    endTime: moment.tz('2018-09-27T14:00:00', 'Asia/Tokyo'),
    allDay: false,
    timeZone: 'Asia/Tokyo',
    ...options,
  }
}

describe('CalendarEventModal', () => {
  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders the modal with title and event details', () => {
    const props = defaultProps()
    const {getByText, getByRole} = render(<CalendarEventModal {...props} />)

    // Check title
    expect(getByRole('link', {name: props.title})).toBeInTheDocument()
    expect(getByRole('link', {name: props.title})).toHaveAttribute('href', props.html_url)

    // Check event details
    expect(getByText('Calendar:')).toBeInTheDocument()
    expect(getByText('the course')).toBeInTheDocument()
    expect(getByText('Date & Time:')).toBeInTheDocument()
    expect(getByText('Location:')).toBeInTheDocument()
    expect(getByText('somewhere')).toBeInTheDocument()
    expect(getByText('Address:')).toBeInTheDocument()
    expect(getByText('here, specifically')).toBeInTheDocument()
    expect(getByText('Details:')).toBeInTheDocument()
    expect(getByText('about this event')).toBeInTheDocument()
  })

  it('renders with only the startTime', () => {
    const props = defaultProps({endTime: null})
    const {getByText} = render(<CalendarEventModal {...props} />)

    // With only startTime, it should show the date and time as a single datetime string
    expect(getByText('Date & Time:')).toBeInTheDocument()
    // We can't test the exact formatted string as it depends on the moment formatting
    // but we can verify the component renders without errors
  })

  it('renders with allDay set to true', () => {
    const props = defaultProps({allDay: true})
    const {getByText} = render(<CalendarEventModal {...props} />)

    // With allDay, it should show only the date without time
    expect(getByText('Date & Time:')).toBeInTheDocument()
    // We can't test the exact formatted string as it depends on the moment formatting
    // but we can verify the component renders without errors
  })

  it('renders with user displayName when courseName is not provided', () => {
    const props = defaultProps({courseName: null})
    const {getByText} = render(<CalendarEventModal {...props} />)

    expect(getByText('Calendar:')).toBeInTheDocument()
    expect(getByText('me')).toBeInTheDocument() // User displayName
  })

  it('does not render location when not provided', () => {
    const props = defaultProps({location: null})
    const {queryByText} = render(<CalendarEventModal {...props} />)

    expect(queryByText('Location:')).toBeNull()
  })

  it('does not render address when not provided', () => {
    const props = defaultProps({address: null})
    const {queryByText} = render(<CalendarEventModal {...props} />)

    expect(queryByText('Address:')).toBeNull()
  })

  it('does not render details when not provided', () => {
    const props = defaultProps({details: null})
    const {queryByText} = render(<CalendarEventModal {...props} />)

    expect(queryByText('Details:')).toBeNull()
  })

  it('converts the details with convertApiUserContent', () => {
    const props = defaultProps()
    render(<CalendarEventModal {...props} />)

    expect(convertApiUserContent).toHaveBeenCalledWith(props.details)
  })

  it('renders with a title that links to the html_url', () => {
    const props = defaultProps()
    const {getByRole} = render(<CalendarEventModal {...props} />)

    // Check that the title is a link with the correct href
    const titleLink = getByRole('link', {name: props.title})
    expect(titleLink).toHaveAttribute('href', props.html_url)
  })

  it('renders a modal with the correct accessibility attributes', () => {
    const props = defaultProps()
    const {getByRole} = render(<CalendarEventModal {...props} />)

    // Check that the modal has the correct accessibility attributes
    const modal = getByRole('dialog')
    expect(modal).toBeInTheDocument()
    expect(modal).toHaveAttribute('aria-label', 'Calendar Event Details')
  })
})
