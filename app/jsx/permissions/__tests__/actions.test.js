/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import $ from 'jquery'
import sinon from 'sinon'

import actions from '../actions'

import {COURSE, ACCOUNT} from '../propTypes'

// This is needed for $.screenReaderFlashMessageExclusive to work.
// TODO: This is terrible, make it unterrible
import 'compiled/jquery.rails_flash_notifications' // eslint-disable-line

const permissions = [
  {
    permission_name: 'add_course',
    label: 'add section',
    contextType: COURSE,
    displayed: undefined
  },
  {
    permission_name: 'irrelevant1',
    label: 'add assignment',
    contectType: COURSE,
    displayed: undefined
  },
  {
    permission_name: 'ignore_this_add',
    label: 'delete everything',
    contextType: COURSE,
    displayed: undefined
  },
  {
    permission_name: 'ignore_because_account',
    label: 'add course',
    contextType: ACCOUNT,
    displayed: undefined
  }
]

it('searchPermissions dispatches updatePermissionsSearch', () => {
  const state = {contextId: 1, permissions, roles: []}
  const dispatchSpy = sinon.spy()
  actions.searchPermissions({permissionSearchString: 'add', contextType: COURSE})(
    dispatchSpy,
    () => state
  )
  const dispatchArgs = dispatchSpy.firstCall.args
  expect(dispatchArgs).toHaveLength(1)
  expect(dispatchArgs[0].type).toEqual('UPDATE_PERMISSIONS_SEARCH')
  expect(dispatchArgs[0].payload.permissionSearchString).toEqual('add')
  expect(dispatchArgs[0].payload.contextType).toEqual(COURSE)
})

it('searchPermissions announces when search is complete', () => {
  const state = {contextId: 1, permissions, roles: []}
  const dispatchSpy = sinon.spy()
  const flashStub = sinon.spy($, 'screenReaderFlashMessageExclusive')
  actions.searchPermissions({permissionSearchString: 'add', contextType: COURSE})(
    dispatchSpy,
    () => state
  )
  expect(flashStub.firstCall.args[0].includes('found')).toEqual(true)
})
