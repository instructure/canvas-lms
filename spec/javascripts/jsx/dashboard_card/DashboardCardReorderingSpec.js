/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import TestUtils from 'react-dom/test-utils'
import {DragDropContext} from 'react-dnd'
import ReactDndTestBackend from 'react-dnd-test-backend'
import DashboardCard from 'jsx/dashboard_card/DashboardCard'
import DraggableDashboardCard from 'jsx/dashboard_card/DraggableDashboardCard'
import getDroppableDashboardCardBox from 'jsx/dashboard_card/getDroppableDashboardCardBox'
import fakeENV from 'helpers/fakeENV'

let cards
let fakeServer

QUnit.module('DashboardCard Reordering', {
  setup() {
    cards = [
      {
        id: '1',
        assetString: 'course_1',
        courseCode: 'DASH-101',
        position: 0,
        originalName: 'Intro to Dashcards 1',
        shortName: 'Dash 101',
        href: '/course/1'
      },
      {
        id: '2',
        assetString: 'course_2',
        courseCode: 'DASH-201',
        position: 1,
        originalName: 'Intermediate Dashcarding',
        shortName: 'Dash 201',
        href: '/course/2'
      },
      {
        id: '3',
        assetString: 'course_3',
        courseCode: 'DASH-301',
        originalName: 'Advanced Dashcards',
        shortName: 'Dash 301',
        href: '/course/3'
      }
    ]

    fakeServer = sinon.fakeServer.create()
    sandbox.fetch.mock('path:/api/v1/courses/1/activity_stream/summary', 200)
    sandbox.fetch.mock('path:/api/v1/courses/2/activity_stream/summary', 200)
    sandbox.fetch.mock('path:/api/v1/courses/3/activity_stream/summary', 200)
  },
  teardown() {
    fakeENV.teardown()
    cards = null
    fakeServer.restore()
  }
})

test('it renders', () => {
  const Box = getDroppableDashboardCardBox()
  const root = TestUtils.renderIntoDocument(
    <Box cardComponent={DashboardCard} courseCards={cards} />
  )
  ok(root)
})

test('cards have opacity of 0 while moving', () => {
  const card = TestUtils.renderIntoDocument(
    <DashboardCard
      cardComponent={DashboardCard}
      {...cards[0]}
      connectDragSource={el => el}
      connectDropTarget={el => el}
      isDragging
    />
  )
  const div = TestUtils.findRenderedDOMComponentWithClass(card, 'ic-DashboardCard')
  equal(div.style.opacity, 0)
})

test('moving a card adjusts the position property', () => {
  const Box = getDroppableDashboardCardBox(DragDropContext(ReactDndTestBackend))
  const root = TestUtils.renderIntoDocument(
    <Box cardComponent={DashboardCard} courseCards={cards} connectDropTarget={el => el} />
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
  equal(renderedAfterDragNDrop[0].getAttribute('aria-label'), 'Intermediate Dashcarding')
  equal(renderedAfterDragNDrop[1].getAttribute('aria-label'), 'Intro to Dashcards 1')
})
