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

import {actions} from '@canvas/conditional-release-stats/react/actions'

QUnit.module('Conditional Release Stats actions')

test('closeSidebar dispatches CLOSE_SIDEBAR action', () => {
  const trigger = {focus: sinon.stub()}
  const dispatch = sinon.stub()
  const getState = sinon.stub().returns({sidebarTrigger: trigger})
  actions.closeSidebar()(dispatch, getState)
  ok(dispatch.calledOnce)
  equal(dispatch.args[0][0].type, 'CLOSE_SIDEBAR')
})

test('closeSidebar focuses sidebar trigger', () => {
  const trigger = {focus: sinon.stub()}
  const dispatch = sinon.stub()
  const getState = sinon.stub().returns({sidebarTrigger: trigger})
  actions.closeSidebar()(dispatch, getState)
  ok(trigger.focus.calledOnce)
})
