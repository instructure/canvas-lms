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
import TestUtils from 'react-dom/test-utils'
import ReactDndTestBackend from 'react-dnd-test-backend'
import {DragDropContext} from 'react-dnd'
import fetchMock from 'fetch-mock'

import getDroppableDashboardCardBox from '../getDroppableDashboardCardBox'
import DashboardCard from '../DashboardCard'
import DraggableDashboardCard from '../DraggableDashboardCard'

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

describe('DraggableDashboardCard reordering', () => {
  beforeEach(() => {
    window.ENV = {
      current_user_id: 1,
    }
    fetchMock.get(/\/api\/v1\/courses\/\d+\/activity_stream\/summary/, [])
    fetchMock.put(/\/api\/v1\/users\/\d+\/colors.*/, {})
  })

  afterEach(() => {
    fetchMock.restore()
  })

  it('renders the provided cards', () => {
    const Box = getDroppableDashboardCardBox()
    const {getByText} = render(<Box cardComponent={DashboardCard} courseCards={CARDS} />)
    ;['DASH-101', 'DASH-201', 'DASH-301'].forEach(name =>
      expect(getByText(name)).toBeInTheDocument()
    )
  })

  it('has an opacity of 0 when moving', () => {
    const {container} = render(
      <DashboardCard
        cardComponent={DashboardCard}
        {...CARDS[0]}
        connectDragSource={el => el}
        connectDropTarget={el => el}
        isDragging={true}
      />
    )
    expect(container.firstChild.style.opacity).toEqual('0')
  })

  it('adjusts the position properly when a card is dragged', () => {
    const Box = getDroppableDashboardCardBox(DragDropContext(ReactDndTestBackend))
    const root = TestUtils.renderIntoDocument(
      <Box cardComponent={DashboardCard} courseCards={CARDS} />
    )

    const backend = root.getManager().getBackend()
    const renderedCardComponents = TestUtils.scryRenderedComponentsWithType(
      root,
      DraggableDashboardCard
    )
    const sourceHandlerId = renderedCardComponents[0].getDecoratedComponentInstance().getHandlerId()
    const targetHandlerId = renderedCardComponents[1].getHandlerId()

    backend.simulateBeginDrag([sourceHandlerId])
    backend.simulateHover([targetHandlerId])
    backend.simulateDrop()

    const renderedAfterDragNDrop = TestUtils.scryRenderedDOMComponentsWithClass(
      root,
      'ic-DashboardCard'
    )

    expect(renderedAfterDragNDrop[0].getAttribute('aria-label')).toEqual('Intermediate Dashcarding')
    expect(renderedAfterDragNDrop[1].getAttribute('aria-label')).toEqual('Intro to Dashcards 1')
  })
})
