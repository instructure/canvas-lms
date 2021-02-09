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
import {render} from '@testing-library/react'
import HomeroomAnnouncementsLayout from '../HomeroomAnnouncementsLayout'

const homeroomAnnouncements = [
  {
    courseId: 1234,
    courseName: 'Homeroom - Mr. Jessie',
    courseUrl: 'http://google.com/course',
    canEdit: true,
    announcement: {
      title: 'Welcome to Class!',
      message: '<p>Yayyyy</p>',
      url: 'http://google.com',
      attachment: {
        display_name: 'exam1.pdf',
        url: 'http://google.com/download',
        filename: '1608134586_366__exam1.pdf'
      }
    }
  },
  {
    courseId: 1235,
    courseName: 'Homeroom 0144232',
    courseUrl: 'http://google.com/course2',
    canEdit: true,
    announcement: {
      title: 'Sign the permission slip!',
      message: '<p>Hello</p>',
      url: 'http://google.com/otherclass'
    }
  },
  {
    courseId: 1236,
    courseName: 'New Homeroom',
    courseUrl: 'http://google.com',
    canEdit: true
  }
]

describe('HomeroomAnnouncementsLayout', () => {
  const getProps = (overrides = {}) => ({
    homeroomAnnouncements,
    ...overrides
  })

  it('renders a view for each child passed', async () => {
    const {findByText} = render(<HomeroomAnnouncementsLayout {...getProps()} />)
    expect(await findByText('Homeroom - Mr. Jessie')).toBeInTheDocument()
    expect(await findByText('Homeroom 0144232')).toBeInTheDocument()
    expect(await findByText('New Homeroom')).toBeInTheDocument()
  })

  it('shows text and button for homeroom courses with no announcements to users that can edit', async () => {
    const {findByText} = render(
      <HomeroomAnnouncementsLayout
        {...getProps({
          homeroomAnnouncements: [
            {
              courseId: 1236,
              courseName: 'New Homeroom',
              courseUrl: 'http://google.com',
              canEdit: true
            }
          ]
        })}
      />
    )
    expect(
      await findByText('Every new announcement shows up in this area. Create your first one now.')
    ).toBeInTheDocument()
    expect(await findByText('Announcement')).toBeInTheDocument()
  })

  it('does not show prompt to create announcement to students', () => {
    const {queryByText} = render(
      <HomeroomAnnouncementsLayout
        {...getProps({
          homeroomAnnouncements: [
            {
              courseId: 1236,
              courseName: 'New Homeroom',
              courseUrl: 'http://google.com',
              canEdit: false
            }
          ]
        })}
      />
    )
    expect(queryByText('New Homeroom')).not.toBeInTheDocument()
    expect(
      queryByText('Every new announcement shows up in this area. Create your first one now.')
    ).not.toBeInTheDocument()
    expect(queryByText('Announcement')).not.toBeInTheDocument()
  })

  it('renders an empty view if no announcements are passed', () => {
    const {container} = render(<HomeroomAnnouncementsLayout />)
    expect(container.firstChild).toBeEmpty()
  })
})
