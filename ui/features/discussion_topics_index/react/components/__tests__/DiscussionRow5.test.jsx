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

import {assignLocation} from '@canvas/util/globalUtils'
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

  it('renders delete item in manage menu if permitted', async () => {
    render(
      <DiscussionRow
        {...makeProps({
          displayManageMenu: true,
          displayDeleteMenuItem: true,
        })}
      />,
    )

    const list = await openManageMenu('Hello World')
    const allKeys = list.querySelectorAll("[class*='menuItem__label']")
    expect(allKeys).toHaveLength(1)
    expect(allKeys[0].textContent.includes('Delete')).toBe(true)
  })

  it('renders lock item in manage menu if permitted', async () => {
    render(
      <DiscussionRow
        {...makeProps({
          displayManageMenu: true,
          displayLockMenuItem: true,
        })}
      />,
    )

    const list = await openManageMenu('Hello World')
    const allKeys = list.querySelectorAll("[class*='menuItem__label']")
    expect(allKeys).toHaveLength(1)
    expect(allKeys[0].textContent.includes('Close for comments')).toBe(true)
  })

  it('renders edit menu item if the user has update permission and discussion has html_url', async () => {
    render(
      <DiscussionRow
        {...makeProps({
          displayManageMenu: true,
          discussion: {
            permissions: {update: true},
            html_url: 'https://example.com',
          },
        })}
      />,
    )

    const list = await openManageMenu('Hello World')
    const allKeys = list.querySelectorAll("[class*='menuItem__label']")
    expect(allKeys).toHaveLength(1)
    expect(allKeys[0].textContent.includes('Edit')).toBe(true)

    const edit = screen.getByText('Edit')
    await user.click(edit)

    expect(assignLocation).toHaveBeenCalledWith('https://example.com/edit')
  })

  it('renders mastery paths menu item if permitted', async () => {
    render(
      <DiscussionRow
        {...makeProps({
          displayManageMenu: true,
          discussion: {
            assignment_id: 2,
          },
          displayMasteryPathsMenuItem: true,
        })}
      />,
    )

    const list = await openManageMenu('Hello World')
    const allKeys = list.querySelectorAll("[class*='menuItem__label']")
    expect(allKeys).toHaveLength(1)
    expect(allKeys[0].textContent.includes('Mastery Paths')).toBe(true)
  })

  it('renders mastery paths link if permitted', () => {
    render(
      <DiscussionRow
        {...makeProps({
          displayManageMenu: true,
          discussion: {
            assignment_id: 2,
          },
          displayMasteryPathsLink: true,
        })}
      />,
    )

    expect(screen.getByText('Mastery Paths')).toBeInTheDocument()
  })

  it('renders ltiTool menu if there are some', async () => {
    render(
      <DiscussionRow
        {...makeProps({
          displayManageMenu: true,
          discussionTopicMenuTools: [
            {
              base_url: 'test.com',
              canvas_icon_class: 'icon-lti',
              icon_url: 'iconUrltest.com',
              title: 'discussion_topic_menu Text',
            },
          ],
        })}
      />,
    )

    const list = await openManageMenu('Hello World')
    const allKeys = list.querySelectorAll("[class*='menuItem__label']")
    expect(allKeys).toHaveLength(1)
    expect(allKeys[0].textContent.includes('discussion_topic_menu Text')).toBe(true)
  })

  it('renders multiple ltiTool menu if there are multiple', async () => {
    render(
      <DiscussionRow
        {...makeProps({
          displayManageMenu: true,
          discussionTopicMenuTools: [
            {
              base_url: 'test.com',
              canvas_icon_class: 'icon-lti',
              icon_url: 'iconUrltest.com',
              title: 'discussion_topic_menu Text',
            },
            {
              base_url: 'test2.com',
              canvas_icon_class: 'icon-lti',
              icon_url: 'iconUrltest2.com',
              title: 'discussion_topic_menu otherText',
            },
          ],
        })}
      />,
    )

    const list = await openManageMenu('Hello World')
    const allKeys = list.querySelectorAll("[class*='menuItem__label']")
    expect(allKeys).toHaveLength(2)
    expect(allKeys[0].textContent.includes('discussion_topic_menu Text')).toBe(true)
    expect(allKeys[1].textContent.includes('discussion_topic_menu otherText')).toBe(true)
  })
})
