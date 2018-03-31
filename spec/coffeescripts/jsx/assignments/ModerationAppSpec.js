/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import ReactDOM from 'react-dom'
import TestUtils from 'react-addons-test-utils'
import ModerationApp from 'jsx/assignments/ModerationApp'
import Actions from 'jsx/assignments/actions/ModerationActions'

QUnit.module('ModerationApp', {
  setup() {
    this.store = {
      subscribe: sinon.spy(),
      dispatch: sinon.spy(),
      getState() {
        return {
          studentList: {
            selectedCount: 0,
            students: [],
            sort: 'asc'
          },
          inflightAction: {
            review: false,
            publish: false
          },
          flashMessage: {
            message: '',
            time: 0
          },
          assignment: {published: false},
          urls: {}
        }
      }
    }
    const permissions = {
      viewGrades: true,
      editGrades: true
    }
    this.moderationApp = TestUtils.renderIntoDocument(
      <ModerationApp store={this.store} permissions={permissions} />
    )
  },
  teardown() {
    this.store = null
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this.moderationApp).parentNode)
  }
})

test('it subscribes to the store when mounted', function() {
  // TODO: Once the rest of the components get dumbed down, this could be
  // changed to be .calledOnce
  ok(this.store.subscribe.called, 'subscribe was called')
})

test('it dispatches a single call to apiGetStudents when mounted', function() {
  ok(this.store.dispatch.calledOnce, 'dispatch was called once')
})

test('it updates state when a change event happens', function() {
  this.store.getState = () => ({newState: true})
  this.moderationApp.handleChange()
  ok(this.moderationApp.state.newState, 'state was updated')
})
