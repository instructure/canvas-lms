/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {act, render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import axe from 'axe-core'
import React from 'react'
import CourseActivitySummaryStore from '../CourseActivitySummaryStore'
import DashboardCard from '../DashboardCard'
import axios from '@canvas/axios'

vi.mock('../CourseActivitySummaryStore')
vi.mock('@canvas/axios')

describe('DashboardCard (Legacy Tests)', () => {
  const defaultProps = {
    shortName: 'Bio 101',
    originalName: 'Biology',
    assetString: 'foo',
    href: '/courses/1',
    courseCode: '101',
    id: '1',
    links: [
      {
        css_class: 'discussions',
        hidden: false,
        icon: 'icon-discussion',
        label: 'Discussions',
        path: '/courses/1/discussion_topics',
      },
    ],
    backgroundColor: '#EF4437',
    image: null,
    isFavorited: true,
    connectDragSource: c => c,
    connectDropTarget: c => c,
  }

  beforeEach(() => {
    CourseActivitySummaryStore.getStateForCourse.mockReturnValue({})
  })

  afterEach(() => {
    vi.clearAllMocks()
    localStorage.clear()
  })

  it('obtains new course activity when course activity is updated', async () => {
    const stream = {
      type: 'DiscussionTopic',
      unread_count: 1,
      count: 2,
    }

    // Mock the initial store response
    CourseActivitySummaryStore.getStateForCourse.mockReturnValue({streams: {1: {stream}}})

    const {rerender} = render(<DashboardCard {...defaultProps} />)

    // Initial render should call getStateForCourse once
    expect(CourseActivitySummaryStore.getStateForCourse).toHaveBeenCalledTimes(1)

    // Update the mock response and trigger a state change
    const updatedStream = {...stream, unread_count: 2}
    CourseActivitySummaryStore.getStateForCourse.mockReturnValue({
      streams: {1: {stream: updatedStream}},
    })

    await act(async () => {
      CourseActivitySummaryStore.setState({streams: {1: {stream: updatedStream}}})
    })

    // Force a re-render
    rerender(<DashboardCard {...defaultProps} />)

    // Should call getStateForCourse again
    expect(CourseActivitySummaryStore.getStateForCourse).toHaveBeenCalledTimes(2)
  })

  it('is accessible', async () => {
    const {container} = render(<DashboardCard {...defaultProps} />)
    const results = await axe.run(container)
    expect(results.violations).toHaveLength(0)
  })

  it('does not have an image when a url is not provided', () => {
    const {queryByText, getByText} = render(<DashboardCard {...defaultProps} />)

    expect(queryByText(`Course image for ${defaultProps.shortName}`)).not.toBeInTheDocument()
    expect(getByText(`Course card color region for ${defaultProps.shortName}`)).toBeInTheDocument()
  })

  it('has an image when a url is provided', () => {
    const props = {...defaultProps, image: 'http://coolUrl'}
    const {getByText} = render(<DashboardCard {...props} />)

    expect(getByText(`Course image for ${props.shortName}`)).toBeInTheDocument()
  })

  it('handles success removing course from favorites', async () => {
    axios.delete.mockResolvedValue({status: 200, data: []})
    const user = userEvent.setup()
    const handleRerender = vi.fn()
    const props = {...defaultProps, onConfirmUnfavorite: handleRerender}

    const {getByText, getByRole} = render(<DashboardCard {...props} />)

    const menuButton = getByRole('button', {
      name: `Choose a color or course nickname or move course card for ${props.shortName}`,
    })
    await user.click(menuButton)

    const moveButton = await waitFor(() => getByText('Move'))
    await user.click(moveButton)

    const unfavoriteButton = await waitFor(() => getByText('Unfavorite'))
    await user.click(unfavoriteButton)

    const submitButton = await waitFor(() => {
      const btn = document.getElementById('confirm_unfavorite_course')
      if (!btn) throw new Error('Button not found')
      return btn
    })

    await user.click(submitButton)

    await waitFor(() => {
      expect(axios.delete).toHaveBeenCalled()
    })

    await waitFor(() => {
      expect(handleRerender).toHaveBeenCalledTimes(1)
    })

    document.querySelectorAll('.confirm-unfavorite-modal-container').forEach(el => el.remove())
  })
})
