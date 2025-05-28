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

import {render, screen} from '@testing-library/react'
import {merge} from 'lodash'
import React from 'react'
import {DiscussionRow} from '../DiscussionRow'
import fakeENV from '@canvas/test-utils/fakeENV'

jest.mock('@canvas/util/globalUtils', () => ({
  assignLocation: jest.fn(),
}))

beforeEach(() => {
  fakeENV.setup()
  // Mock Date.now() to return a consistent timestamp for stable testing
  jest.spyOn(Date, 'now').mockReturnValue(new Date('2025-01-01T00:00:00Z').getTime())
  // Mock timezone to ensure consistent date formatting
  jest.spyOn(Intl, 'DateTimeFormat').mockImplementation(() => ({
    format: date => {
      const d = new Date(date)
      return `${d.getUTCMonth() + 1}/${d.getUTCDate()}/${d.getUTCFullYear()}`
    },
  }))
})

afterEach(() => {
  fakeENV.teardown()
  jest.restoreAllMocks()
})

// We can't call the wrapped component because a lot of these tests are depending
// on the class component instances. So we've got to cobble up enough of the date
// formatter to send in as a prop.
const dateFormatter = date => {
  const fmtr = Intl.DateTimeFormat('en').format
  try {
    if (date === null) return ''
    return fmtr(date instanceof Date ? date : new Date(date))
  } catch (e) {
    if (e instanceof RangeError) return ''
    throw e
  }
}

describe('DiscussionRow', () => {
  const makeProps = (props = {}) =>
    merge(
      {
        discussion: {
          id: '1',
          position: 1,
          published: true,
          title: 'Hello World',
          message: 'Foo bar bar baz boop beep bop Foo',
          posted_at: 'January 10, 2019 at 10:00 AM',
          can_unpublish: true,
          author: {
            id: '5',
            name: 'John Smith',
            display_name: 'John Smith',
            html_url: '',
            avatar_image_url: null,
          },
          permissions: {},
          subscribed: false,
          read_state: 'unread',
          unread_count: 0,
          discussion_subentry_count: 5,
          locked: false,
          html_url: '',
          user_count: 10,
          last_reply_at: new Date(2018, 1, 14, 0, 0, 0, 0),
          ungraded_discussion_overrides: [],
        },
        canPublish: false,
        canReadAsAdmin: true,
        displayDeleteMenuItem: false,
        displayDuplicateMenuItem: false,
        displayLockMenuItem: false,
        displayManageMenu: false,
        displayPinMenuItem: false,
        displayDifferentiatedModulesTray: false,
        isMasterCourse: false,
        toggleSubscriptionState: () => {},
        cleanDiscussionFocus: () => {},
        duplicateDiscussion: () => {},
        updateDiscussion: () => {},
        masterCourseData: {},
        setCopyTo: () => {},
        setSendTo: () => {},
        setSendToOpen: () => {},
        deleteDiscussion: () => {},
        DIRECT_SHARE_ENABLED: false,
        contextType: '',
        dateFormatter,
        breakpoints: {mobileOnly: false},
      },
      props,
    )

  it('renders the latest available until date for ungraded overrides', () => {
    const earlierDate = new Date('2026-05-15T00:00:00Z')
    const laterDate = new Date('2027-05-15T00:00:00Z')
    const discussion = {
      ungraded_discussion_overrides: [
        {assignment_override: {lock_at: earlierDate}},
        {assignment_override: {lock_at: laterDate}},
      ],
    }
    render(<DiscussionRow {...makeProps({discussion})} />)

    // Find element that contains text starting with "Available until"
    const availabilityElement = screen.getByText(/^Available until/)
    expect(availabilityElement).toBeInTheDocument()

    // The component should show the latest (furthest in future) date
    // Expected format: "Available until 5/15/2027"
    expect(availabilityElement.textContent).toContain('5/15/2027')
  })
})
