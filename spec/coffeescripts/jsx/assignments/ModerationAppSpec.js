#
# Copyright (C) 2015 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'react'
  'react-dom'
  'react-addons-test-utils'
  'jsx/assignments/ModerationApp'
  'jsx/assignments/actions/ModerationActions'
], (React, ReactDOM, TestUtils, ModerationApp, Actions) ->

  QUnit.module 'ModerationApp',
    setup: ->
      @store =
        subscribe: sinon.spy()
        dispatch: sinon.spy()
        getState: -> {
          studentList: {
            selectedCount: 0
            students: []
            sort: 'asc'
          },
          inflightAction: {
            review: false,
            publish: false
          },
          flashMessage: {
            message: "",
            time: 0
          },
          assignment: {
            published: false
          },
          urls: {}
        }
      permissions =
        viewGrades: true
        editGrades: true

      @moderationApp = TestUtils.renderIntoDocument(
        React.createElement(ModerationApp, store: @store, permissions: permissions)
      )


    teardown: ->
      @store = null
      ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(@moderationApp).parentNode)

  test 'it subscribes to the store when mounted', ->
    # TODO: Once the rest of the components get dumbed down, this could be
    #       changed to be .calledOnce
    ok @store.subscribe.called, 'subscribe was called'

  test 'it dispatches a single call to apiGetStudents when mounted', ->
    ok @store.dispatch.calledOnce, 'dispatch was called once'

  test 'it updates state when a change event happens', ->
    @store.getState = -> {
      newState: true
    }
    @moderationApp.handleChange()

    ok @moderationApp.state.newState, 'state was updated'
