/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import {fireEvent, render, screen} from '@testing-library/react'
import AnnouncementRow from '../AnnouncementRow'

const mockLockIconView = {
  render: jest.fn(),
  remove: jest.fn(),
}

jest.mock('@canvas/lock-icon', () => jest.fn(() => mockLockIconView))

const defaultProps = (props = {}) => ({
  canManage: false,
  masterCourseData: {},
  ...props,
  announcement: {
    id: '1',
    position: 1,
    published: true,
    title: 'Hello World',
    message: 'Foo bar bar baz boop beep bop Foo',
    posted_at: 'January 10, 2019 at 10:00 AM',
    author: {
      id: '5',
      name: 'John Smith',
      display_name: 'John Smith',
      html_url: '',
      avatar_image_url: null,
    },
    read_state: 'unread',
    unread_count: 0,
    discussion_subentry_count: 0,
    locked: false,
    html_url: '',
    user_count: 10,
    permissions: {
      reply: true,
    },
    ...props.announcement,
  },
})

const renderAnnouncementRow = (props = {}) => render(<AnnouncementRow {...defaultProps(props)} />)

describe('AnnouncementRow', () => {
  it('renders the AnnouncementRow component', () => {
    renderAnnouncementRow()

    expect(screen.getByText('Hello World')).toBeInTheDocument()
  })

  it('renders a checkbox if canManage: true', () => {
    renderAnnouncementRow({canManage: true})

    expect(screen.getByRole('checkbox')).toBeInTheDocument()
  })

  it('renders no checkbox if canManage: false', () => {
    renderAnnouncementRow({canManage: false})

    expect(screen.queryByRole('checkbox')).not.toBeInTheDocument()
  })

  it('renders UnreadBadge if announcement has replies > 0', () => {
    renderAnnouncementRow({announcement: {unread_count: 2, discussion_subentry_count: 5}})

    expect(
      screen.getByRole('tooltip', {
        name: /2 unread replies/i,
      })
    ).toBeInTheDocument()
  })

  it('renders UnreadBadge if announcement has replies == 0', () => {
    renderAnnouncementRow({announcement: {discussion_subentry_count: 0}})

    expect(screen.getByText(/unread/)).toBeInTheDocument()
  })

  it('renders "Delayed" date label if announcement is delayed', () => {
    const tomorrow = new Date()
    const dateOptions = {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      timeZone: 'UTC',
    }
    const announcement = {}

    tomorrow.setDate(tomorrow.getDate() + 1)
    announcement.delayed_post_at = tomorrow.toISOString()

    renderAnnouncementRow({announcement})

    const expectedDate = new Intl.DateTimeFormat('en-US', dateOptions).format(tomorrow)

    expect(screen.getByText(/delayed until:/i)).toBeInTheDocument()
    expect(screen.getByText(new RegExp(expectedDate, 'i'))).toBeInTheDocument()
  })

  it('renders "Posted on" date label if announcement is not delayed', () => {
    const test_date = '1/24/2018'

    renderAnnouncementRow({announcement: {delayed_post_at: null, posted_at: test_date}})

    expect(screen.getByText(/Jan 24, 2018/)).toBeInTheDocument()
  })

  it('renders the SectionsTooltip component if canHaveSections: true', () => {
    const announcement = {user_count: 200}

    renderAnnouncementRow({announcement, canHaveSections: true})

    expect(screen.getByText('All Sections')).toBeInTheDocument()
  })

  it('does not render the SectionsTooltip component if canHaveSections: false', () => {
    const announcement = {user_count: 200, canHaveSections: false}

    renderAnnouncementRow({announcement})

    expect(screen.queryByText('All Sections')).not.toBeInTheDocument()
  })

  it('renders the SectionsTooltip component with sections', () => {
    const announcement = {
      sections: [
        {id: 6, course_id: 1, name: 'section 4', user_count: 2},
        {id: 5, course_id: 1, name: 'section 2', user_count: 1},
      ],
    }

    renderAnnouncementRow({announcement, canHaveSections: true})

    expect(screen.getByText('2 Sections')).toBeInTheDocument()
    expect(screen.getByText('section 4')).toBeInTheDocument()
    expect(screen.getByText('section 2')).toBeInTheDocument()
  })

  it('does not render master course lock icon if masterCourseData is not provided', () => {
    const masterCourseData = null

    const {container} = renderAnnouncementRow({masterCourseData})

    expect(container.querySelector('.lock-icon .lock-icon')).not.toBeInTheDocument()
  })

  it('renders master course lock icon if masterCourseData is provided', () => {
    const masterCourseData = {isMasterCourse: true, masterCourse: {id: '1'}}

    renderAnnouncementRow({masterCourseData})

    expect(mockLockIconView.render).toHaveBeenCalled()
  })

  it('renders reply button icon if user has reply permission', () => {
    renderAnnouncementRow({announcement: {permissions: {reply: true}}})

    expect(screen.getByRole('link', {name: /reply/i})).toBeInTheDocument()
  })

  it('does not render reply button icon if user does not have reply permission', () => {
    renderAnnouncementRow({announcement: {permissions: {reply: false}}})

    expect(screen.queryByRole('link', {name: /reply/i})).not.toBeInTheDocument()
  })

  it('removes non-text content from announcement message', () => {
    const messageHtml = `
      <p data-testid="custom-html-text1">This is a message within custom HTML</p>
      <img data-testid="custom-html-image" src="/apple-touch-icon.png"  alt=""/>
      <p data-testid="custom-html-text2">This is also a message within custom HTML</p>
    `

    renderAnnouncementRow({announcement: {message: messageHtml}})

    expect(screen.getByText(/This is a message within custom HTML/)).toBeInTheDocument()
    expect(screen.getByText(/This is also a message within custom HTML/)).toBeInTheDocument()
    expect(screen.queryByTestId('custom-html-image')).not.toBeInTheDocument()
    expect(screen.queryByTestId('custom-html-text1')).not.toBeInTheDocument()
    expect(screen.queryByTestId('custom-html-text2')).not.toBeInTheDocument()
    expect(screen.queryByText('/images/stuff/things.png')).not.toBeInTheDocument()
  })

  it('does not render manage menu if canManage is false', () => {
    renderAnnouncementRow({canManage: false})

    expect(screen.queryByText(/Manage options for /)).not.toBeInTheDocument()
  })

  it('renders manage menu if canManage is true', () => {
    renderAnnouncementRow({canManage: true})

    expect(screen.getByText(/Manage options for /)).toBeInTheDocument()
  })

  it('does not render Allow Comments menu item if announcements are globally locked', () => {
    renderAnnouncementRow({
      canManage: true,
      canDelete: false,
      announcementsLocked: true,
    })

    fireEvent.click(screen.getByRole('button', {name: /Manage options for /}))

    expect(screen.queryByText(/Allow Comments/)).not.toBeInTheDocument()
  })
})
