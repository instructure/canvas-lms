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

import {render, screen, waitFor} from '@testing-library/react'
import userEvent, {PointerEventsCheckLevel} from '@testing-library/user-event'
import {merge} from 'lodash'
import React from 'react'
import {DiscussionRow} from '../DiscussionRow'

jest.mock('@canvas/util/globalUtils', () => ({
  assignLocation: jest.fn(),
}))

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

const user = userEvent.setup({pointerEventsCheck: PointerEventsCheckLevel.Never})

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

  const openManageMenu = async title => {
    const menu = screen.getByText(`Manage options for ${title}`)
    expect(menu).toBeInTheDocument()
    await user.click(menu)
    const list = await waitFor(() => screen.getByRole('menu'))
    expect(list).toBeInTheDocument()

    return list
  }

  const oldEnv = window.ENV

  afterEach(() => {
    window.ENV = oldEnv
  })

  it('renders the DiscussionRow component', () => {
    expect(() => {
      render(<DiscussionRow {...makeProps()} />)
    }).not.toThrow()
  })

  it('renders UnreadBadge if discussion has replies > 0', () => {
    const discussion = {discussion_subentry_count: 5}
    render(<DiscussionRow {...makeProps({discussion})} />)
    const nodes = screen.getAllByText('0 unread replies')
    expect(nodes).toHaveLength(2)
  })

  it('renders title as a link', () => {
    const discussion = {id: '1', locked: false, title: 'blerp', html_url: 'https://example.com'}
    render(<DiscussionRow {...makeProps({discussion})} />)
    const link = screen.getByTestId(`discussion-link-${discussion.id}`)
    expect(link.textContent.includes(discussion.title)).toBe(true)
    expect(link.tagName.toLowerCase()).toBe('a')
    expect(link.getAttribute('href')).toBe('https://example.com')
  })

  it('when feature flag is off, anonymous title is plain text ', () => {
    window.ENV.discussion_anonymity_enabled = false
    const discussion = {id: '1', locked: false, title: 'blerp', anonymous_state: 'full_anonymity'}
    render(<DiscussionRow {...makeProps({discussion})} />)
    expect(screen.getByTestId(`discussion-title-${discussion.id}`)).toBeInTheDocument()
    expect(screen.queryByTestId(`discussion-link-${discussion.id}`)).not.toBeInTheDocument()
  })

  it('renders Correct screen reader message for locking discussions', async () => {
    const updateDiscussionMock = jest.fn()
    const discussion = {locked: false, title: 'blerp'}
    render(
      <DiscussionRow
        {...makeProps({
          displayManageMenu: true,
          displayLockMenuItem: true,
          updateDiscussion: updateDiscussionMock,
          discussion,
        })}
      />,
    )

    await openManageMenu(discussion.title)
    const lock = screen.getByText('Close discussion blerp for comments')
    await user.click(lock)

    expect(updateDiscussionMock).toHaveBeenCalledWith(
      expect.anything(),
      expect.anything(),
      expect.objectContaining({
        successMessage: 'Lock discussion blerp succeeded',
        failMessage: 'Lock discussion blerp failed',
      }),
      expect.anything(),
    )
  })

  it('renders Correct screen reader message for unlocking discussions', async () => {
    const updateDiscussionMock = jest.fn()
    const discussion = {locked: true, title: 'blerp'}
    render(
      <DiscussionRow
        {...makeProps({
          displayManageMenu: true,
          displayLockMenuItem: true,
          updateDiscussion: updateDiscussionMock,
          discussion,
        })}
      />,
    )

    await openManageMenu(discussion.title)
    const unlock = screen.getByText('Open discussion blerp for comments')
    await user.click(unlock)

    expect(updateDiscussionMock).toHaveBeenCalledWith(
      expect.anything(),
      expect.anything(),
      expect.objectContaining({
        successMessage: 'Unlock discussion blerp succeeded',
        failMessage: 'Unlock discussion blerp failed',
      }),
      expect.anything(),
    )
  })
})
