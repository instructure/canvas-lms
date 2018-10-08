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

import Actions from 'jsx/assignments/actions/IndexMenuActions'

QUnit.module('AssignmentsIndexMenuActions')

test('setModalOpen returns the expected action', () => {
  const expectedAction1 = {
    type: Actions.SET_MODAL_OPEN,
    payload: true
  }
  const actualAction1 = Actions.setModalOpen(true)
  deepEqual(expectedAction1, actualAction1)

  const expectedAction2 = {
    type: Actions.SET_MODAL_OPEN,
    payload: false
  }
  const actualAction2 = Actions.setModalOpen(false)
  deepEqual(expectedAction2, actualAction2)
})

test('launchTool returns the expected action', () => {
  const tool = {foo: 'bar'}
  const expectedAction = {
    type: Actions.LAUNCH_TOOL,
    payload: tool
  }
  const actualAction = Actions.launchTool(tool)
  deepEqual(expectedAction, actualAction)
})

test('setWeighted returns the expected action', () => {
  const expectedAction1 = {
    type: Actions.SET_WEIGHTED,
    payload: true
  }
  const actualAction1 = Actions.setWeighted(true)
  deepEqual(expectedAction1, actualAction1)

  const expectedAction2 = {
    type: Actions.SET_WEIGHTED,
    payload: false
  }
  const actualAction2 = Actions.setWeighted(false)
  deepEqual(expectedAction2, actualAction2)
})
