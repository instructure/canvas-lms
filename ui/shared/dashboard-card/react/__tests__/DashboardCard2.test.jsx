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

import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {act, render, waitFor} from '@testing-library/react'
import axe from 'axe-core'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import React from 'react'
import CourseActivitySummaryStore from '../CourseActivitySummaryStore'
import DashboardCard from '../DashboardCard'

jest.mock('../CourseActivitySummaryStore')
jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashError: jest.fn(),
}))

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

  const server = setupServer()

  beforeAll(() => server.listen())
  afterEach(() => {
    server.resetHandlers()
    localStorage.clear()
    jest.clearAllMocks()
    CourseActivitySummaryStore.getStateForCourse.mockReturnValue({})
  })
  afterAll(() => server.close())

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
    const handleRerender = jest.fn()
    const props = {...defaultProps, onConfirmUnfavorite: handleRerender}

    const {getByText} = render(<DashboardCard {...props} />)

    act(() => {
      getByText(
        `Choose a color or course nickname or move course card for ${props.shortName}`,
      ).click()
    })
    act(() => {
      getByText('Move').click()
    })
    act(() => {
      getByText('Unfavorite').click()
    })
    server.use(http.delete('*/users/self/favorites/courses/*', () => HttpResponse.json([])))

    act(() => {
      getByText('Submit').click()
    })

    await waitFor(() => {
      expect(handleRerender).toHaveBeenCalledTimes(1)
    })
  })

  // fickle
  it.skip('handles failure removing course from favorites', async () => {
    const handleRerender = jest.fn()
    const props = {...defaultProps, onConfirmUnfavorite: handleRerender}

    const {getByText, getByRole} = render(<DashboardCard {...props} />)

    // Click the menu button
    const menuButton = getByRole('button', {
      name: `Choose a color or course nickname or move course card for ${props.shortName}`,
    })
    await act(async () => {
      menuButton.click()
    })

    // Wait for menu to be visible and click "Move"
    const moveButton = await waitFor(() => getByText('Move'))
    await act(async () => {
      moveButton.click()
    })

    // Wait for submenu and click "Unfavorite"
    const unfavoriteButton = await waitFor(() => getByText('Unfavorite'))
    await act(async () => {
      unfavoriteButton.click()
    })

    // Wait for confirmation dialog and click "Submit"
    const submitButton = await waitFor(() => getByRole('button', {name: 'Submit'}))

    server.use(
      http.delete(
        '*/users/self/favorites/courses/*',
        () => new HttpResponse(JSON.stringify({error: 'Unauthorized'}), {status: 403}),
      ),
    )

    await act(async () => {
      submitButton.click()
    })

    // Wait for the error alert
    await waitFor(
      () => {
        expect(showFlashError).toHaveBeenCalledWith(
          'We were unable to remove this course from your favorites.',
        )
      },
      {timeout: 3000},
    )
  })
})
