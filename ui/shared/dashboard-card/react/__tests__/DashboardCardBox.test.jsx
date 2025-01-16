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

import React from 'react'
import {render, waitFor, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {DragDropContext} from 'react-dnd'
import ReactDndTestBackend from 'react-dnd-test-backend'
import fetchMock from 'fetch-mock'

import DashboardCard from '../DashboardCard'
import getDroppableDashboardCardBox from '../getDroppableDashboardCardBox'
import CourseActivitySummaryStore from '../CourseActivitySummaryStore'

describe('DashboardCardBox', () => {
  let props
  const defaultProps = {
    cardComponent: DashboardCard,
    courseCards: [
      {
        id: '1',
        isFavorited: true,
        courseName: 'Bio 101',
        assetString: 'course_1',
      },
      {
        id: '2',
        isFavorited: true,
        courseName: 'Philosophy 201',
        assetString: 'course_1',
      },
    ],
  }

  beforeEach(() => {
    props = {...defaultProps}

    // Mock all color-related API calls
    fetchMock.put(/\/api\/v1\/users\/.*\/colors\/.*/, {
      status: 200,
      headers: {'Content-Type': 'application/json'},
      body: {},
    })

    fetchMock.get(/\/api\/v1\/users\/.*\/colors/, {
      status: 200,
      headers: {'Content-Type': 'application/json'},
      body: {},
    })

    jest.spyOn(CourseActivitySummaryStore, 'getStateForCourse').mockReturnValue({})
  })

  afterEach(() => {
    fetchMock.reset()
    jest.clearAllMocks()
  })

  const renderComponent = () => {
    const Box = getDroppableDashboardCardBox(DragDropContext(ReactDndTestBackend))
    return {
      ...render(<Box connectDropTarget={el => el} ref={() => {}} {...props} />),
      Box,
    }
  }

  describe('rendering', () => {
    it('renders dashboard cards for each provided courseCard', () => {
      renderComponent()
      const cards = document.querySelectorAll('.ic-DashboardCard')
      expect(cards).toHaveLength(props.courseCards.length)
    })

    it('renders headers for both published/unpublished courses in split view', () => {
      props.showSplitDashboardView = true
      renderComponent()
      const headers = document.querySelectorAll('.ic-DashboardCard__box__header')
      expect(headers).toHaveLength(2)
    })

    it('correctly splits course cards into published and unpublished in split view', () => {
      props.courseCards = [
        {...props.courseCards[0], published: false},
        {...props.courseCards[1], published: true},
      ]
      props.showSplitDashboardView = true
      renderComponent()
      const headers = document.querySelectorAll('.ic-DashboardCard__box__header')
      expect(headers[0].textContent).toContain('Published Courses (1)')
      expect(headers[1].textContent).toContain('Unpublished Courses (1)')
    })

    it('correctly renders empty headers in split view', () => {
      props.courseCards = []
      props.showSplitDashboardView = true
      renderComponent()
      const dashboardBox = document.querySelector('.unpublished_courses_redesign')
      expect(dashboardBox.textContent).toContain('No courses to display')
    })
  })

  describe('card interactions', () => {
    it('removes unfavorited card from dashboard cards', async () => {
      const user = userEvent.setup()
      const {rerender, Box} = renderComponent()

      // Mock the unfavorite API call
      fetchMock.delete('/api/v1/users/self/favorites/courses/1', {
        status: 200,
        body: {},
      })

      const cards = document.querySelectorAll('.ic-DashboardCard')
      const initialCardCount = cards.length

      const moreButton = cards[0].querySelector('.icon-more')
      await user.click(moreButton)

      const moveTab = screen.getByRole('tab', {name: /Move/})
      await user.click(moveTab)

      const unfavoriteButton = screen.getByText(/Unfavorite/)
      await user.click(unfavoriteButton)

      const submitButton = screen.getByRole('button', {name: /Submit/})
      await user.click(submitButton)

      // Update props to simulate card being unfavorited
      props.courseCards = props.courseCards.filter(card => card.id !== '1')
      rerender(<Box connectDropTarget={el => el} ref={() => {}} {...props} />)

      await waitFor(() => {
        const updatedCards = document.querySelectorAll('.ic-DashboardCard')
        expect(updatedCards).toHaveLength(initialCardCount - 1)
      })
    })
  })
})
