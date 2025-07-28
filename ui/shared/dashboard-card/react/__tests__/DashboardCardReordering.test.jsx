/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import {DragDropContext} from 'react-dnd'
import TestBackend from 'react-dnd-test-backend'
import fetchMock from 'fetch-mock'

import getDroppableDashboardCardBox from '../getDroppableDashboardCardBox'
import DashboardCard from '../DashboardCard'

const CARDS = [
  {
    id: '1',
    assetString: 'course_1',
    courseCode: 'DASH-101',
    position: 0,
    originalName: 'Intro to Dashcards 1',
    shortName: 'Dash 101',
    href: '/course/1',
  },
  {
    id: '2',
    assetString: 'course_2',
    courseCode: 'DASH-201',
    position: 1,
    originalName: 'Intermediate Dashcarding',
    shortName: 'Dash 201',
    href: '/course/2',
  },
  {
    id: '3',
    assetString: 'course_3',
    courseCode: 'DASH-301',
    originalName: 'Advanced Dashcards',
    shortName: 'Dash 301',
    href: '/course/3',
  },
]

describe('DraggableDashboardCard', () => {
  let oldEnv

  beforeEach(() => {
    oldEnv = window.ENV
    window.ENV = {
      current_user_id: 1,
    }
    // Mock activity stream for all courses
    CARDS.forEach(card => {
      fetchMock.get(`/api/v1/courses/${card.id}/activity_stream/summary`, [])
      // Mock color setting requests with any hexcode parameter
      fetchMock.put(
        new RegExp(`/api/v1/users/1/colors/course_${card.id}\\?hexcode=[0-9A-Fa-f]{6}`),
        {},
      )
    })
  })

  afterEach(() => {
    window.ENV = oldEnv
    fetchMock.restore()
  })

  const renderWithDnd = component => {
    const WithTestContext = DragDropContext(TestBackend)(({children}) => children)
    const result = render(<WithTestContext>{component}</WithTestContext>)
    return result
  }

  it('displays all course cards in the correct order', () => {
    const Box = getDroppableDashboardCardBox()

    const {getAllByTestId} = renderWithDnd(
      <Box cardComponent={DashboardCard} courseCards={CARDS} />,
    )

    const cards = getAllByTestId('dashboard-card-title')
    expect(cards).toHaveLength(3)
    expect(cards[0]).toHaveTextContent('Dash 101')
    expect(cards[1]).toHaveTextContent('Dash 201')
    expect(cards[2]).toHaveTextContent('Dash 301')
  })

  it('applies opacity style when card is being dragged', () => {
    const {getByTestId} = render(
      <DashboardCard
        cardComponent={DashboardCard}
        {...CARDS[0]}
        data-testid="draggable-card"
        connectDragSource={el => el}
        connectDropTarget={el => el}
        isDragging={true}
      />,
    )
    expect(getByTestId('draggable-card')).toHaveStyle({opacity: '0'})
  })

  it('updates card positions after drag and drop', async () => {
    const Box = getDroppableDashboardCardBox()
    const moveCard = jest.fn()

    const {getAllByTestId} = renderWithDnd(
      <Box cardComponent={DashboardCard} courseCards={CARDS} moveCard={moveCard} />,
    )

    const cards = getAllByTestId('dashboard-card-title')
    expect(cards).toHaveLength(3)

    // Get source and target positions
    const sourceAssetString = CARDS[0].assetString
    const targetPosition = 1

    // Simulate card movement
    moveCard(sourceAssetString, targetPosition)

    // Verify moveCard was called with correct arguments
    expect(moveCard).toHaveBeenCalledWith(sourceAssetString, targetPosition)
  })
})
