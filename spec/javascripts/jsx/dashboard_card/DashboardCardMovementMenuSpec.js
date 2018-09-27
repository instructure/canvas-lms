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
import DashboardCardMovementMenu from 'jsx/dashboard_card/DashboardCardMovementMenu'

QUnit.module('DashboardCardMovementMenu')

test('it calls handleMove properly', () => {
  const handleMoveSpy = sinon.spy()
  const props = {
    assetString: 'course_1',
    cardTitle: 'Strategery 101',
    handleMove: handleMoveSpy,
    menuOptions: {
      canMoveLeft: true,
      canMoveRight: true,
      canMoveToBeginning: true,
      canMoveToEnd: true
    }
  }
  const menu = TestUtils.renderIntoDocument(<DashboardCardMovementMenu {...props} />)

  // handleMoveCard returns a function that's the actual handler.
  menu.handleMoveCard(2)()

  ok(handleMoveSpy.calledWith('course_1', 2))
})
