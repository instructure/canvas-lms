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
import CourseItemRow from '../CourseItemRow'
import AnnouncementModel from '@canvas/discussions/backbone/models/Announcement'

const mockLockIconView = {
  render: jest.fn(),
  remove: jest.fn(),
}

jest.mock('@canvas/lock-icon', () => jest.fn(() => mockLockIconView))

const defaultProps = {
  title: 'Hello CourseItemRow title',
  body: <p>Hello CourseItemRow body</p>,
  id: '5',
  position: 1,
  published: true,
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
}

const renderCourseItemRow = (props = {}) => {
  const activeProps = {...defaultProps, ...props}

  return render(<CourseItemRow {...activeProps} />)
}

describe('CourseItemRow', () => {
  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders the CourseItemRow component', () => {
    renderCourseItemRow()

    expect(screen.getByText('Hello CourseItemRow body')).toBeInTheDocument()
  })

  it("renders the CourseItemRow component when author doesn't exist", () => {
    renderCourseItemRow({author: null})

    expect(screen.getByText('Hello CourseItemRow body')).toBeInTheDocument()
  })

  it('renders children inside content column', () => {
    const {container} = renderCourseItemRow({
      body: <span className="find-me2" />,
      sectionToolTip: <span className="find-me3" />,
      replyButton: <span className="find-me4" />,
    })

    expect(screen.getByText('Hello CourseItemRow title')).toBeInTheDocument()
    expect(container.querySelector('.ic-item-row__content-col .find-me2')).toBeInTheDocument()
    expect(container.querySelector('.ic-item-row__content-col .find-me3')).toBeInTheDocument()
    expect(container.querySelector('.ic-item-row__content-col .find-me4')).toBeInTheDocument()
  })

  it('renders clickable children inside content link', () => {
    const {container} = renderCourseItemRow({
      replyButton: <span className="find-me" />,
    })

    expect(container.querySelector('a.ic-item-row__content-link h3')).toBeInTheDocument()
    expect(container.querySelector('a.ic-item-row__content-link .find-me')).toBeInTheDocument()
  })

  it('renders actions inside actions wrapper', () => {
    const {container} = renderCourseItemRow({
      actionsContent: <span className="find-me" />,
    })

    expect(container.querySelector('.ic-item-row__meta-actions .find-me')).toBeInTheDocument()
  })

  it('renders metaContent inside meta content wrapper', () => {
    const {container} = renderCourseItemRow({
      metaContent: <span className="find-me" />,
    })

    expect(container.querySelector('.ic-item-row__meta-content .find-me')).toBeInTheDocument()
  })

  it('renders a checkbox if selectable: true', () => {
    renderCourseItemRow({selectable: true})

    expect(screen.getByRole('checkbox')).toBeInTheDocument()
  })

  it('renders a drag handle if draggable: true', () => {
    const {container} = renderCourseItemRow({draggable: true})

    expect(container.querySelector('.ic-item-row__drag-col')).toBeInTheDocument()
  })

  it('renders inputted icon', () => {
    renderCourseItemRow({icon: <span data-testid="custom-icon" />})

    expect(screen.queryByTestId('custom-icon')).toBeInTheDocument()
  })

  it('renders no checkbox if selectable: false', () => {
    renderCourseItemRow({selectable: false})

    expect(screen.queryByRole('checkbox')).not.toBeInTheDocument()
  })

  it('renders an accessible avatar if showAvatar: true', () => {
    renderCourseItemRow({showAvatar: true})

    expect(screen.getByAltText('John Smith')).toBeInTheDocument()
  })

  it('renders no avatar if showAvatar: false', () => {
    renderCourseItemRow({showAvatar: false})

    expect(screen.queryByAltText('John Smith')).not.toBeInTheDocument()
  })

  it('renders unread indicator if isRead: false', () => {
    renderCourseItemRow({isRead: false})

    expect(screen.getByText(/unread,/)).toBeInTheDocument()
  })

  it('renders no unread indicator if isRead: true', () => {
    renderCourseItemRow({isRead: true})

    expect(screen.queryByText(/unread,/)).not.toBeInTheDocument()
  })

  it('passes down className prop to component', () => {
    const {container} = renderCourseItemRow({className: 'find-me'})

    expect(container.querySelector('.ic-item-row')).toHaveClass('find-me')
  })

  it('renders master course lock icon if isMasterCourse', () => {
    const masterCourse = {
      courseData: {isMasterCourse: true, masterCourse: {id: '1'}},
      getLockOptions: () => ({
        model: new AnnouncementModel(defaultProps.announcement),
        unlockedText: '',
        lockedText: '',
        course_id: '3',
        content_id: '5',
        content_type: 'announcement',
      }),
    }

    renderCourseItemRow({masterCourse})

    expect(mockLockIconView.render).toHaveBeenCalled()
  })

  it('renders peer review icon if peer review', () => {
    const {container} = renderCourseItemRow({peerReview: true})

    expect(container.querySelector('.ic-item-row__peer_review')).toBeInTheDocument()
  })

  it('renders master course lock icon if isChildCourse', () => {
    const masterCourse = {
      courseData: {isChildCourse: true, masterCourse: {id: '1'}},
      getLockOptions: () => ({
        model: new AnnouncementModel(defaultProps.announcement),
        unlockedText: '',
        lockedText: '',
        course_id: '3',
        content_id: '5',
        content_type: 'announcement',
      }),
    }

    renderCourseItemRow({masterCourse})

    expect(mockLockIconView.render).toHaveBeenCalled()
  })

  it('renders no master course lock icon if no master course data provided', () => {
    const masterCourse = {
      courseData: {},
      getLockOptions: () => ({}),
    }

    renderCourseItemRow({masterCourse})

    expect(mockLockIconView.render).not.toHaveBeenCalled()
  })

  it('renders no master course lock icon if isMasterCourse and isChildCourse are false', () => {
    const masterCourse = {
      courseData: {isMasterCourse: false, isChildCourse: false},
      getLockOptions: () => ({}),
    }

    renderCourseItemRow({masterCourse})

    expect(mockLockIconView.render).not.toHaveBeenCalled()
  })

  it('calls onSelectChanged when checkbox is toggled', () => {
    const onSelectedChanged = jest.fn()

    renderCourseItemRow({selectable: true, onSelectedChanged})

    fireEvent.click(screen.getByRole('checkbox'))

    expect(onSelectedChanged).toHaveBeenCalledWith({id: '5', selected: true})
  })

  it('renders no manage menu when showManageMenu is false', () => {
    renderCourseItemRow({showManageMenu: false})

    expect(screen.queryByText(/Manage options for /)).not.toBeInTheDocument()
  })

  it('renders manage menu when showManageMenu is true and manageMenuOptions is not empty', () => {
    renderCourseItemRow({showManageMenu: true, manageMenuOptions: () => null})

    expect(screen.getByText(/Manage options for /)).toBeInTheDocument()
  })

  it('does not render a clickable div if the body is empty', () => {
    const {container} = renderCourseItemRow({body: null})

    expect(container.querySelectorAll('.ic-item-row__content-link')).toHaveLength(1)
  })
})
