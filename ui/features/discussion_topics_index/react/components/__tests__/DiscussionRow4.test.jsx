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

  it('does not insert the manage menu list if we have not clicked it yet', () => {
    render(
      <DiscussionRow
        {...makeProps({
          displayManageMenu: true,
          onMoveDiscussion: () => {},
        })}
      />,
    )
    // We still should show the menu thingy itself
    expect(screen.getByText('Manage options for Hello World')).toBeInTheDocument()
    expect(screen.queryByRole('menu')).not.toBeInTheDocument()
  })

  it('manage menu items do appear upon click', async () => {
    render(
      <DiscussionRow
        {...makeProps({
          displayManageMenu: true,
          onMoveDiscussion: () => {},
        })}
      />,
    )

    await openManageMenu('Hello World')
    expect(screen.getByText('Move To')).toBeInTheDocument()
  })

  it('does not render sharing menu options if not DIRECT_SHARE_ENABLED', async () => {
    const props = makeProps({displayManageMenu: true, DIRECT_SHARE_ENABLED: false})
    render(<DiscussionRow {...props} />)

    await openManageMenu('Hello World')
    expect(screen.queryByText('Move To', {exact: false})).not.toBeInTheDocument()
    expect(screen.queryByText('Send To', {exact: false})).not.toBeInTheDocument()
  })

  it('only leaves pin/unpin open/close for comments, and delete when inaccessibleDueToAnonymity', async () => {
    window.ENV.discussion_anonymity_enabled = false
    const discussion = {locked: false, title: 'blerp', anonymous_state: 'full_anonymity'}
    render(
      <DiscussionRow
        {...makeProps({
          discussion,
          displayManageMenu: true,
          DIRECT_SHARE_ENABLED: true,
          displayDeleteMenuItem: true,
          displayPinMenuItem: true,
          displayLockMenuItem: true,
          canPublish: true,
          published: false,
        })}
      />,
    )

    const list = await openManageMenu(discussion.title)
    const allKeys = list.querySelectorAll("[class*='menuItem__label']")
    expect(allKeys).toHaveLength(3)
    expect(allKeys[0].textContent.includes('Close for comments')).toBe(true)
    expect(allKeys[1].textContent.includes('Pin')).toBe(true)
    expect(allKeys[2].textContent.includes('Delete')).toBe(true)

    expect(screen.queryByText('Publish blerp')).not.toBeInTheDocument()
    expect(screen.queryByText('Subscribe to blerp')).not.toBeInTheDocument()
  })

  it('renders sharing menu options if DIRECT_SHARE_ENABLED', async () => {
    const props = makeProps({displayManageMenu: true, DIRECT_SHARE_ENABLED: true})
    render(<DiscussionRow {...props} />)

    await openManageMenu('Hello World')
    expect(screen.getByText('Copy To', {exact: false})).toBeInTheDocument()
    expect(screen.getByText('Send To', {exact: false})).toBeInTheDocument()
  })

  it('opens the copyTo tray when menu item is selected', async () => {
    const copyMock = jest.fn()
    const props = makeProps({
      displayManageMenu: true,
      DIRECT_SHARE_ENABLED: true,
      setCopyTo: copyMock,
    })
    render(<DiscussionRow {...props} />)

    await openManageMenu('Hello World')
    const copyTo = screen.getByText('Copy To', {exact: false})
    await user.click(copyTo)

    expect(copyMock).toHaveBeenCalledWith(
      expect.objectContaining({
        open: true,
        selection: {discussion_topics: [props.discussion.id]},
      }),
    )
  })

  it('opens the sendTo tray when menu item is selected', async () => {
    const sendMock = jest.fn()
    const props = makeProps({
      displayManageMenu: true,
      DIRECT_SHARE_ENABLED: true,
      setSendTo: sendMock,
    })
    render(<DiscussionRow {...props} />)

    await openManageMenu('Hello World')
    const sendToNode = screen.getByText('Send To', {exact: false})
    await user.click(sendToNode)

    expect(sendMock).toHaveBeenCalledWith(
      expect.objectContaining({
        open: true,
        selection: {
          content_type: 'discussion_topic',
          content_id: props.discussion.id,
        },
      }),
    )
  })

  it('renders availability information on graded discussions', () => {
    render(
      <DiscussionRow
        {...makeProps({
          discussion: {
            assignment: {
              lock_at: '2018-07-01T05:59:00Z',
              unlock_at: '2018-06-21T06:00:00Z',
            },
          },
        })}
      />,
    )

    expect(screen.getByText('No longer available')).toBeInTheDocument()
  })

  it('renders move-to in manage menu if permitted', async () => {
    render(
      <DiscussionRow
        {...makeProps({
          displayManageMenu: true,
          onMoveDiscussion: () => {},
        })}
      />,
    )

    const list = await openManageMenu('Hello World')
    const allKeys = list.querySelectorAll("[class*='menuItem__label']")
    expect(allKeys).toHaveLength(1)
    expect(allKeys[0].textContent.includes('Move To')).toBe(true)
  })

  describe('pin item', () => {
    it('renders if permitted', async () => {
      render(
        <DiscussionRow
          {...makeProps({
            displayManageMenu: true,
            displayPinMenuItem: true,
          })}
        />,
      )

      const list = await openManageMenu('Hello World')
      const allKeys = list.querySelectorAll('#togglepinned-discussion-menu-option')
      expect(allKeys).toHaveLength(1)
      expect(allKeys[0].textContent.includes('Pin')).toBe(true)
    })

    it('should add trackable attribute correctly', async () => {
      render(
        <DiscussionRow
          {...makeProps({
            displayManageMenu: true,
            displayPinMenuItem: true,
          })}
        />,
      )

      const list = await openManageMenu('Hello World')
      const allKeys = list.querySelectorAll('#togglepinned-discussion-menu-option')
      expect(allKeys).toHaveLength(1)
      expect(allKeys[0]).toHaveAttribute('data-action-state', 'pinButton')
    })

    describe('when pinned', () => {
      it('renders unpin item in manage menu if permitted', async () => {
        render(
          <DiscussionRow
            {...makeProps({
              displayManageMenu: true,
              displayPinMenuItem: true,
              discussion: {pinned: true},
            })}
          />,
        )

        const list = await openManageMenu('Hello World')
        const allKeys = list.querySelectorAll('#togglepinned-discussion-menu-option')
        expect(allKeys).toHaveLength(1)
        expect(allKeys[0].textContent.includes('Unpin')).toBe(true)
      })

      it('should add trackable attribute correctly', async () => {
        render(
          <DiscussionRow
            {...makeProps({
              displayManageMenu: true,
              displayPinMenuItem: true,
              discussion: {pinned: true},
            })}
          />,
        )

        const list = await openManageMenu('Hello World')
        const allKeys = list.querySelectorAll('#togglepinned-discussion-menu-option')
        expect(allKeys).toHaveLength(1)
        expect(allKeys[0]).toHaveAttribute('data-action-state', 'unpinButton')
      })
    })
  })

  describe('lock item', () => {
    it('renders if permitted', async () => {
      render(
        <DiscussionRow
          {...makeProps({
            displayManageMenu: true,
            displayLockMenuItem: true,
          })}
        />,
      )

      const list = await openManageMenu('Hello World')
      const allKeys = list.querySelectorAll('#togglelocked-discussion-menu-option')
      expect(allKeys).toHaveLength(1)
      expect(allKeys[0].textContent.includes('Close for comments')).toBe(true)
    })

    it('should add trackable attribute correctly', async () => {
      render(
        <DiscussionRow
          {...makeProps({
            displayManageMenu: true,
            displayLockMenuItem: true,
            discussion: {locked: false},
          })}
        />,
      )

      const list = await openManageMenu('Hello World')
      const allKeys = list.querySelectorAll('#togglelocked-discussion-menu-option')
      expect(allKeys).toHaveLength(1)
      expect(allKeys[0]).toHaveAttribute('data-action-state', 'lockButton')
    })

    describe('when locked', () => {
      it('renders unpin item in manage menu if permitted', async () => {
        render(
          <DiscussionRow
            {...makeProps({
              displayManageMenu: true,
              displayLockMenuItem: true,
              discussion: {locked: true},
            })}
          />,
        )

        const list = await openManageMenu('Hello World')
        const allKeys = list.querySelectorAll('#togglelocked-discussion-menu-option')
        expect(allKeys).toHaveLength(1)
        expect(allKeys[0].textContent.includes('Open for comments')).toBe(true)
      })

      it('should add trackable attribute correctly', async () => {
        render(
          <DiscussionRow
            {...makeProps({
              displayManageMenu: true,
              displayLockMenuItem: true,
              discussion: {locked: true},
            })}
          />,
        )

        const list = await openManageMenu('Hello World')
        const allKeys = list.querySelectorAll('#togglelocked-discussion-menu-option')
        expect(allKeys).toHaveLength(1)
        expect(allKeys[0]).toHaveAttribute('data-action-state', 'unlockButton')
      })
    })
  })

  it('renders speedgrader link in manage menu if permitted', async () => {
    window.ENV.show_additional_speed_grader_links = true
    render(
      <DiscussionRow
        {...makeProps({
          displayManageMenu: true,
          discussion: {
            assignment: {
              lock_at: '2018-07-01T05:59:00Z',
              unlock_at: '2018-06-21T06:00:00Z',
              id: '50',
            },
          },
        })}
      />,
    )

    const list = await openManageMenu('Hello World')
    const allKeys = list.querySelectorAll("[class*='menuItem__label']")
    expect(allKeys).toHaveLength(1)
    expect(allKeys[0].textContent.includes('SpeedGrader')).toBe(true)
  })

  it('renders duplicate item in manage menu if permitted', async () => {
    render(
      <DiscussionRow
        {...makeProps({
          displayManageMenu: true,
          displayDuplicateMenuItem: true,
        })}
      />,
    )

    const list = await openManageMenu('Hello World')

    const allKeys = list.querySelectorAll("[class*='menuItem__label']")
    expect(allKeys).toHaveLength(1)
    expect(allKeys[0].textContent.includes('Duplicate')).toBe(true)
  })
})
