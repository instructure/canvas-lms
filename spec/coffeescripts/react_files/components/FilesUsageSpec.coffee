#
# Copyright (C) 2014 - present Instructure, Inc.
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
  'jquery'
  'jsx/files/FilesUsage'
], (React, ReactDOM, TestUtils, $, FilesUsage) ->

  QUnit.module 'FilesUsage#update',
    filesUpdateTest: (props, test) ->
      @server = sinon.fakeServer.create()
      @filesUsage = TestUtils.renderIntoDocument(React.createElement(FilesUsage, props))

      test()

      ReactDOM.unmountComponentAtNode(@filesUsage.getDOMNode().parentNode)

      @server.restore()

  test "makes a get request with contextType and contextId", ->
    @stub($, 'get')
    @filesUpdateTest {contextType: 'users', contextId: 4}, =>
       @filesUsage.update()
       ok $.get.calledWith(@filesUsage.url()), "makes get request with correct params"

  test "sets state with ajax requests returned data", ->
    data = {foo: 'bar'}

    @filesUpdateTest {contextType: 'users', contextId: 4}, =>
      @server.respondWith @filesUsage.url(), [
        200
        'Content-Type': 'application/json'
        JSON.stringify data
      ]

      @spy(@filesUsage, 'setState')

      @filesUsage.update()
      @server.respond()

      ok @filesUsage.setState.calledWith(data), 'called set state with returned get request data'

  test 'update called after component mounted', ->
    @filesUpdateTest {contextType: 'users', contextId: 4}, =>
      @stub(@filesUsage, 'update').returns(true)
      @filesUsage.componentDidMount()
      ok @filesUsage.update.calledOnce, "called update after it mounted"
