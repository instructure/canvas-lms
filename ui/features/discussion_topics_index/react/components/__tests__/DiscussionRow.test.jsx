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
import {render, screen, waitFor} from '@testing-library/react'
import userEvent, {PointerEventsCheckLevel} from '@testing-library/user-event'
import {merge} from 'lodash'
import {DiscussionRow} from '../DiscussionRow'

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
          subscribed: false,
          read_state: 'unread',
          unread_count: 0,
          discussion_subentry_count: 5,
          locked: false,
          html_url: '',
          user_count: 10,
          last_reply_at: new Date(2018, 1, 14, 0, 0, 0, 0),
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
      },
      props
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
    expect(nodes.length).toBe(2)
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
      />
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
      expect.anything()
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
      />
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
      expect.anything()
    )
  })

  it('does not render UnreadBadge if discussion has replies == 0', () => {
    const discussion = {discussion_subentry_count: 0}
    render(<DiscussionRow {...makeProps({discussion})} />)
    expect(screen.queryByText('0 unread replies')).not.toBeInTheDocument()
  })

  it('renders ReadBadge if discussion is unread', () => {
    const discussion = {read_state: 'unread'}
    render(<DiscussionRow {...makeProps({discussion})} />)
    expect(screen.getByTestId('ic-blue-unread-badge')).toBeInTheDocument()
  })

  it('does not render ReadBadge if discussion is read', () => {
    const discussion = {read_state: 'read'}
    render(<DiscussionRow {...makeProps({discussion})} />)
    expect(screen.queryByTestId('ic-blue-unread-badge')).not.toBeInTheDocument()
  })

  it('renders the subscription ToggleIcon', () => {
    render(<DiscussionRow {...makeProps()} />)
    expect(screen.getByText('Subscribe to Hello World')).toBeInTheDocument()
  })

  it('disables publish button when can_unpublish is false', () => {
    const discussion = {can_unpublish: false}
    render(<DiscussionRow {...makeProps({canPublish: true, discussion})} />)
    const button = screen.getByRole('button', {name: 'Unpublish Hello World'})
    expect(button.hasAttribute('disabled')).toBe(true)
  })

  it('allows to publish even if you cannot unpublish', () => {
    const discussion = {can_unpublish: false, published: false}
    render(<DiscussionRow {...makeProps({canPublish: true, discussion})} />)
    const button = screen.getByRole('button', {name: 'Publish Hello World'})
    expect(button.hasAttribute('disabled')).toBe(false)
  })

  it('renders the publish ToggleIcon', () => {
    const discussion = {published: false}
    render(<DiscussionRow {...makeProps({canPublish: true, discussion})} />)
    expect(screen.getByText('Publish Hello World')).toBeInTheDocument()
  })

  it('when feature flag is off, renders anonymous discussion lock explanation for read_as_admin', () => {
    window.ENV.discussion_anonymity_enabled = false
    const discussion = {locked: false, title: 'blerp', anonymous_state: 'full_anonymity'}
    render(<DiscussionRow {...makeProps({canReadAsAdmin: true, discussion})} />)
    expect(screen.getByText('Discussions/Announcements Redesign')).toBeInTheDocument()
  })

  it('when feature flag is off, renders anonymous discussion unavailable for students, etc.', () => {
    window.ENV.discussion_anonymity_enabled = false
    const discussion = {locked: false, title: 'blerp', anonymous_state: 'full_anonymity'}
    render(<DiscussionRow {...makeProps({canReadAsAdmin: false, discussion})} />)
    expect(screen.getByText('Unavailable')).toBeInTheDocument()
  })

  it('when feature flag is off, renders partially anonymous discussion unavailable for students, etc.', () => {
    window.ENV.discussion_anonymity_enabled = false
    const discussion = {locked: false, title: 'blerp', anonymous_state: 'partial_anonymity'}
    render(<DiscussionRow {...makeProps({canReadAsAdmin: false, discussion})} />)
    expect(screen.getByText('Unavailable')).toBeInTheDocument()
  })

  it('renders "Delayed until" date label if discussion is delayed', () => {
    const delayedDate = new Date()
    delayedDate.setYear(delayedDate.getFullYear() + 1)
    const discussion = {delayed_post_at: delayedDate.toISOString()}
    render(<DiscussionRow {...makeProps({discussion})} />)
    expect(screen.getAllByText('Not available until', {exact: false}).length).toBe(2)
  })

  it('renders a last reply at date', () => {
    render(<DiscussionRow {...makeProps()} />)
    expect(screen.getAllByText('Last post at 2/14', {exact: false}).length).toBe(2)
  })

  it('does not render last reply at date if there is none', () => {
    const discussion = {last_reply_at: ''}
    render(<DiscussionRow {...makeProps({discussion})} />)
    expect(screen.queryByText('Last post at', {exact: false})).not.toBeInTheDocument()
  })

  it('renders available until if appropriate', () => {
    const futureDate = new Date()
    futureDate.setYear(futureDate.getFullYear() + 1)
    const discussion = {lock_at: futureDate}
    render(<DiscussionRow {...makeProps({discussion})} />)
    expect(screen.getAllByText('Available until', {exact: false}).length).toBe(2)
    // We need a relative date to ensure future-ness, so we can't really insist
    // on a given date element appearing this time
  })

  it('renders locked at if appropriate', () => {
    const pastDate = new Date()
    pastDate.setYear(pastDate.getFullYear() - 1)
    const discussion = {lock_at: pastDate}
    render(<DiscussionRow {...makeProps({discussion})} />)
    expect(screen.getAllByText('No longer available', {exact: false}).length).toBe(2)
    // We need a relative date to ensure past-ness, so we can't really insist
    // on a given date element appearing this time
  })

  it('renders nothing if currently available and no end date', () => {
    render(<DiscussionRow {...makeProps()} />)
    expect(screen.queryByText('Available until', {exact: false})).not.toBeInTheDocument()
    expect(screen.queryByText('Not available until', {exact: false})).not.toBeInTheDocument()
    expect(screen.queryByText('No longer available', {exact: false})).not.toBeInTheDocument()
  })

  it('renders due date if graded with a due date', () => {
    const props = makeProps({
      discussion: {
        assignment: {
          due_at: '2018-07-01T05:59:00Z',
        },
      },
    })
    render(<DiscussionRow {...props} />)
    expect(screen.getAllByText('Due ', {exact: false}).length).toBe(2)
    expect(screen.queryByText('To do', {exact: false})).not.toBeInTheDocument()
  })

  it('renders to do date if ungraded with a to do date', () => {
    const props = makeProps({
      discussion: {
        todo_date: '2018-07-01T05:59:00Z',
      },
    })
    render(<DiscussionRow {...props} />)
    expect(screen.getByText('To do ', {exact: false})).toBeInTheDocument()
    expect(screen.queryByText('Due', {exact: false})).not.toBeInTheDocument()
  })

  it('renders neither a due or to do date if neither are available', () => {
    render(<DiscussionRow {...makeProps()} />)
    expect(screen.queryByText('Due', {exact: false})).not.toBeInTheDocument()
    expect(screen.queryByText('To do', {exact: false})).not.toBeInTheDocument()
  })

  it('renders the SectionsTooltip component', () => {
    const discussion = {user_count: 200}
    render(<DiscussionRow {...makeProps({discussion})} />)
    expect(screen.getByText('All sections', {exact: false})).toBeInTheDocument()
  })

  it('renders the SectionsTooltip component with sections', () => {
    const discussion = {
      sections: [
        {id: 6, course_id: 1, name: 'section 4', user_count: 2},
        {id: 5, course_id: 1, name: 'section 2', user_count: 1},
      ],
    }
    render(<DiscussionRow {...makeProps({discussion})} />)
    expect(screen.getByText('2 Sections')).toBeInTheDocument()
    expect(screen.getByText('section 4')).toBeInTheDocument()
    expect(screen.getByText('section 2')).toBeInTheDocument()
  })

  it('includes Anonymous Discussion prefix when discussion is anonymous', () => {
    window.ENV.discussion_anonymity_enabled = false
    const discussion = {
      sections: [
        {id: 6, course_id: 1, name: 'section 4', user_count: 2},
        {id: 5, course_id: 1, name: 'section 2', user_count: 1},
      ],
      anonymous_state: 'full_anonymity',
    }
    render(<DiscussionRow {...makeProps({discussion})} />)
    expect(screen.getByText('Anonymous Discussion | 2 Sections')).toBeInTheDocument()
    expect(screen.getByText('section 4')).toBeInTheDocument()
    expect(screen.getByText('section 2')).toBeInTheDocument()
  })

  it('includes Partially Anonymous Discussion prefix when discussion is anonymous', () => {
    window.ENV.discussion_anonymity_enabled = false
    const discussion = {
      sections: [
        {id: 6, course_id: 1, name: 'section 4', user_count: 2},
        {id: 5, course_id: 1, name: 'section 2', user_count: 1},
      ],
      anonymous_state: 'partial_anonymity',
    }
    render(<DiscussionRow {...makeProps({discussion})} />)
    expect(screen.getByText('Partially Anonymous Discussion | 2 Sections')).toBeInTheDocument()
    expect(screen.getByText('section 4')).toBeInTheDocument()
    expect(screen.getByText('section 2')).toBeInTheDocument()
  })

  it('does not render the SectionsTooltip component on a graded discussion', () => {
    const discussion = {user_count: 200, assignment: true}
    render(<DiscussionRow {...makeProps({discussion})} />)
    expect(screen.queryByText('All sections', {exact: false})).not.toBeInTheDocument()
  })

  it('does not render the SectionsTooltip component on a group discussion', () => {
    const discussion = {user_count: 200, group_category_id: 13}
    render(<DiscussionRow {...makeProps({discussion})} />)
    expect(screen.queryByText('All sections', {exact: false})).not.toBeInTheDocument()
  })

  it('does not render the SectionsTooltip component within a group context', () => {
    const discussion = {user_count: 200}
    render(<DiscussionRow {...makeProps({discussion, contextType: 'group'})} />)
    expect(screen.queryByText('All sections', {exact: false})).not.toBeInTheDocument()
  })

  it('does not render the SectionsTooltip component in a blueprint course', () => {
    const discussion = {user_count: 200}
    render(<DiscussionRow {...makeProps({discussion, isMasterCourse: true})} />)
    expect(screen.queryByText('All sections', {exact: false})).not.toBeInTheDocument()
  })

  it('does not render master course lock icon if masterCourseData is not provided', () => {
    const masterCourseData = null
    const ref = React.createRef()
    render(<DiscussionRow ref={ref} {...makeProps({masterCourseData})} />)
    expect(ref.current.masterCourseLock).toBeFalsy()
    const container = screen.getByTestId('ic-master-course-icon-container')
    expect(container.hasAttribute('data-tooltip')).toBe(false)
  })

  it('renders master course lock icon if masterCourseData is provided', () => {
    const masterCourseData = {isMasterCourse: true, masterCourse: {id: '1'}}
    const ref = React.createRef()
    render(<DiscussionRow ref={ref} {...makeProps({masterCourseData})} />)
    expect(ref.current.masterCourseLock).toBeTruthy()
    const container = screen.getByTestId('ic-master-course-icon-container')
    expect(container.hasAttribute('data-tooltip')).toBe(true)
  })

  it('renders drag icon', () => {
    render(<DiscussionRow {...makeProps({draggable: true})} />)
    expect(screen.getByTestId('ic-drag-handle-icon-container')).toBeInTheDocument()
  })

  it('does not render manage menu if not permitted', () => {
    render(<DiscussionRow {...makeProps({displayManageMenu: false})} />)
    expect(screen.queryByText('Manage options for Hello World')).not.toBeInTheDocument()
  })

  it('does not insert the manage menu list if we have not clicked it yet', () => {
    render(
      <DiscussionRow
        {...makeProps({
          displayManageMenu: true,
          onMoveDiscussion: () => {},
        })}
      />
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
      />
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
      />
    )

    const list = await openManageMenu(discussion.title)
    const allKeys = list.querySelectorAll('li')
    expect(allKeys.length).toBe(3)
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
      })
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
      })
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
      />
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
      />
    )

    const list = await openManageMenu('Hello World')
    const allKeys = list.querySelectorAll('li')
    expect(allKeys.length).toBe(1)
    expect(allKeys[0].textContent.includes('Move To')).toBe(true)
  })

  it('renders pin item in manage menu if permitted', async () => {
    render(
      <DiscussionRow
        {...makeProps({
          displayManageMenu: true,
          displayPinMenuItem: true,
        })}
      />
    )

    const list = await openManageMenu('Hello World')
    const allKeys = list.querySelectorAll('li')
    expect(allKeys.length).toBe(1)
    expect(allKeys[0].textContent.includes('Pin')).toBe(true)
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
      />
    )

    const list = await openManageMenu('Hello World')
    const allKeys = list.querySelectorAll('li')
    expect(allKeys.length).toBe(1)
    expect(allKeys[0].textContent.includes('SpeedGrader')).toBe(true)
  })

  it('renders duplicate item in manage menu if permitted', async () => {
    render(
      <DiscussionRow
        {...makeProps({
          displayManageMenu: true,
          displayDuplicateMenuItem: true,
        })}
      />
    )

    const list = await openManageMenu('Hello World')
    const allKeys = list.querySelectorAll('li')
    expect(allKeys.length).toBe(1)
    expect(allKeys[0].textContent.includes('Duplicate')).toBe(true)
  })

  it('renders delete item in manage menu if permitted', async () => {
    render(
      <DiscussionRow
        {...makeProps({
          displayManageMenu: true,
          displayDeleteMenuItem: true,
        })}
      />
    )

    const list = await openManageMenu('Hello World')
    const allKeys = list.querySelectorAll('li')
    expect(allKeys.length).toBe(1)
    expect(allKeys[0].textContent.includes('Delete')).toBe(true)
  })

  it('renders lock item in manage menu if permitted', async () => {
    render(
      <DiscussionRow
        {...makeProps({
          displayManageMenu: true,
          displayLockMenuItem: true,
        })}
      />
    )

    const list = await openManageMenu('Hello World')
    const allKeys = list.querySelectorAll('li')
    expect(allKeys.length).toBe(1)
    expect(allKeys[0].textContent.includes('Close for comments')).toBe(true)
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
      />
    )

    const list = await openManageMenu('Hello World')
    const allKeys = list.querySelectorAll('li')
    expect(allKeys.length).toBe(1)
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
      />
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
      />
    )

    const list = await openManageMenu('Hello World')
    const allKeys = list.querySelectorAll('li')
    expect(allKeys.length).toBe(1)
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
      />
    )

    const list = await openManageMenu('Hello World')
    const allKeys = list.querySelectorAll('li')
    expect(allKeys.length).toBe(2)
    expect(allKeys[0].textContent.includes('discussion_topic_menu Text')).toBe(true)
    expect(allKeys[1].textContent.includes('discussion_topic_menu otherText')).toBe(true)
  })
})
