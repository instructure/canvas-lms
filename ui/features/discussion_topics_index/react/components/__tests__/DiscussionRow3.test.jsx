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

  const oldEnv = window.ENV

  afterEach(() => {
    window.ENV = oldEnv
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
    expect(screen.getAllByText('Due ', {exact: false})).toHaveLength(2)
    expect(screen.queryByText('To do', {exact: false})).not.toBeInTheDocument()
  })

  it('renders checkpoint information', () => {
    const props = makeProps({
      discussion: {
        reply_to_entry_required_count: 2,
        assignment: {
          checkpoints: [
            {
              tag: 'reply_to_topic',
              points_possible: 20,
              due_at: '2024-09-14T05:59:00Z',
            },
            {
              tag: 'reply_to_entry',
              points_possible: 10,
              due_at: '2024-09-21T05:59:00Z',
            },
          ],
        },
      },
    })
    render(<DiscussionRow {...props} />)
    expect(screen.queryByText('Reply to topic:', {exact: false})).toBeInTheDocument()
    expect(screen.queryByText('Required replies (2):', {exact: false})).toBeInTheDocument()
    expect(
      screen.queryByText(props.dateFormatter('2024-09-14T05:59:00Z'), {exact: false}),
    ).toBeInTheDocument()
    expect(
      screen.queryByText(props.dateFormatter('2024-09-21T05:59:00Z'), {exact: false}),
    ).toBeInTheDocument()
    expect(screen.queryByText('No Due Date', {exact: false})).not.toBeInTheDocument()
  })

  it('renders checkpoint information without due dates', () => {
    const props = makeProps({
      discussion: {
        reply_to_entry_required_count: 4,
        assignment: {
          checkpoints: [
            {
              tag: 'reply_to_topic',
              points_possible: 10,
              due_at: null,
            },
            {
              tag: 'reply_to_entry',
              points_possible: 20,
              due_at: null,
            },
          ],
        },
      },
    })
    render(<DiscussionRow {...props} />)
    expect(
      screen.queryByText('Reply to topic: No Due Date Required replies (4): No Due Date', {
        exact: false,
      }),
    ).toBeInTheDocument()
  })

  it('renders checkpoint information without crashing when only one checkpoint exists', () => {
    const consoleSpy = jest.spyOn(console, 'error').mockImplementation(() => {})

    const props = makeProps({
      discussion: {
        reply_to_entry_required_count: 1,
        assignment: {
          checkpoints: [
            {
              tag: 'reply_to_topic',
              points_possible: 20,
              due_at: '2024-09-14T05:59:00Z',
            },
            // Missing the reply_to_entry checkpoint to simulate the error condition.
          ],
        },
      },
    })
    render(<DiscussionRow {...props} />)

    // Ensure that the component renders the available checkpoint correctly,
    // and falls back to "No Due Date" for the missing checkpoint.
    expect(screen.queryByText('Reply to topic:', {exact: false})).toBeInTheDocument()
    expect(screen.queryByText('Required replies (1):', {exact: false})).toBeInTheDocument()
    expect(
      screen.queryByText(props.dateFormatter('2024-09-14T05:59:00Z'), {exact: false}),
    ).toBeInTheDocument()
    expect(screen.queryByText('No Due Date', {exact: false})).toBeInTheDocument()

    // Verify that the console.error was called for the inconsistent checkpoint scenario
    expect(consoleSpy).toHaveBeenCalledWith(
      'Error: Inconsistent checkpoints - Only one of the reply-to-topic or reply-to-entry checkpoint exists.',
    )

    consoleSpy.mockRestore()
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

  it('does not render master course lock icon if masterCourseData is not provided', () => {
    const masterCourseData = null
    const ref = React.createRef()
    render(<DiscussionRow ref={ref} {...makeProps({masterCourseData})} />)
    expect(ref.current.masterCourseLock).toBeFalsy()
    const container = screen.queryByTestId('ic-master-course-icon-container')
    expect(container).not.toBeInTheDocument()
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
})
