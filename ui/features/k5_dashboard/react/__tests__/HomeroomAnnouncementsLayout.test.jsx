/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {render, waitFor} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import HomeroomAnnouncementsLayout from '../HomeroomAnnouncementsLayout'

const homeroomAnnouncements = [
  {
    courseId: '1234',
    courseName: 'Homeroom - Mr. Jessie',
    courseUrl: 'http://google.com/course',
    canEdit: true,
    canReadAnnouncements: true,
    announcement: {
      id: '1234',
      title: 'Welcome to Class!',
      message: '<p>Yayyyy</p>',
      url: 'http://google.com',
      postedDate: new Date(),
      attachment: {
        display_name: 'exam1.pdf',
        url: 'http://google.com/download',
        filename: '1608134586_366__exam1.pdf',
      },
    },
    published: true,
  },
  {
    courseId: '1235',
    courseName: 'Homeroom 0144232',
    courseUrl: 'http://google.com/course2',
    canEdit: true,
    canReadAnnouncements: true,
    announcement: {
      id: '1235',
      title: 'Sign the permission slip!',
      message: '<p>Hello</p>',
      url: 'http://google.com/otherclass',
      postedDate: new Date(),
    },
    published: true,
  },
  {
    courseId: '1236',
    courseName: 'New Homeroom',
    courseUrl: 'http://google.com',
    canEdit: true,
    canReadAnnouncements: true,
    published: true,
  },
]

describe('HomeroomAnnouncementsLayout', () => {
  const getProps = (overrides = {}) => ({
    homeroomAnnouncements,
    loading: false,
    ...overrides,
  })

  beforeEach(() => {
    fetchMock.get(
      /\/api\/v1\/announcements/,
      {
        body: '[]',
        headers: {
          Link: '</api/v1/announcements>; rel="current",</api/v1/announcements>; rel="first",</api/v1/announcements>; rel="last"',
        },
      },
      {}
    )
  })

  afterEach(() => {
    localStorage.clear()
    fetchMock.restore()
  })

  it('renders a view for each child passed', () => {
    const {getByText} = render(<HomeroomAnnouncementsLayout {...getProps()} />)
    expect(getByText('Homeroom - Mr. Jessie')).toBeInTheDocument()
    expect(getByText('Homeroom 0144232')).toBeInTheDocument()
    expect(getByText('New Homeroom')).toBeInTheDocument()
  })

  it('shows text and button for homeroom courses with no announcements to users that can edit', async () => {
    const {findByText, getByText} = render(
      <HomeroomAnnouncementsLayout
        {...getProps({
          homeroomAnnouncements: [
            {
              courseId: '1236',
              courseName: 'New Homeroom',
              courseUrl: 'http://google.com',
              canEdit: true,
              canReadAnnouncements: true,
            },
          ],
        })}
      />
    )
    expect(
      await findByText('New announcements show up in this area. Create a new announcement now.')
    ).toBeInTheDocument()
    expect(getByText('Announcement')).toBeInTheDocument()
  })

  it('does not show prompt to create announcement to students', async () => {
    const {queryByText} = render(
      <HomeroomAnnouncementsLayout
        {...getProps({
          homeroomAnnouncements: [
            {
              courseId: '1236',
              courseName: 'New Homeroom',
              courseUrl: 'http://google.com',
              canEdit: false,
              canReadAnnouncements: true,
            },
          ],
        })}
      />
    )
    // The Homeroom header is rendered by default, then removed
    // if the request for old announcements returns nothing.
    // Wait for the fetch to complete before continuing.
    await waitFor(() => fetchMock.done())
    expect(queryByText('New Homeroom')).not.toBeInTheDocument()
    expect(
      queryByText('New announcements show up in this area. Create a new announcement now.')
    ).not.toBeInTheDocument()
    expect(queryByText('Announcement')).not.toBeInTheDocument()
  })

  it('renders an empty view if no announcements are passed', () => {
    const {container} = render(
      <HomeroomAnnouncementsLayout homeroomAnnouncements={[]} loading={false} />
    )
    expect(container.firstChild).toBeEmptyDOMElement()
  })

  it('renders loading skeletons if loading', () => {
    const {getByText, queryByText} = render(
      <HomeroomAnnouncementsLayout {...getProps({loading: true, homeroomAnnouncements: []})} />
    )
    expect(getByText('Loading Homeroom Course Name')).toBeInTheDocument()
    expect(getByText('Loading Announcement Title')).toBeInTheDocument()
    expect(getByText('Loading Announcement Content')).toBeInTheDocument()
    expect(queryByText('Welcome to Class!')).not.toBeInTheDocument()
  })
})
