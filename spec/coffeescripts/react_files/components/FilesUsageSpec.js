/*
 * Copyright (C) 2014 - present Instructure, Inc.
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
import TestUtils from 'react-dom/test-utils'
import $ from 'jquery'
import FilesUsage from 'ui/features/files/react/components/FilesUsage.js'

QUnit.module('FilesUsage#update', {
  filesUpdateTest(props, test) {
    this.server = sinon.fakeServer.create()
    this.filesUsage = TestUtils.renderIntoDocument(<FilesUsage {...props} />)
    test()
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this.filesUsage).parentNode)
    return this.server.restore()
  }
})

test('makes a get request with contextType and contextId', function() {
  sandbox.stub($, 'get')
  return this.filesUpdateTest(
    {
      contextType: 'users',
      contextId: 4
    },
    () => {
      this.filesUsage.update()
      ok($.get.calledWith(this.filesUsage.url()), 'makes get request with correct params')
    }
  )
})

test('sets state with ajax requests returned data', function() {
  const data = {foo: 'bar'}
  return this.filesUpdateTest(
    {
      contextType: 'users',
      contextId: 4
    },
    () => {
      this.server.respondWith(this.filesUsage.url(), [
        200,
        {'Content-Type': 'application/json'},
        JSON.stringify(data)
      ])
      sandbox.spy(this.filesUsage, 'setState')
      this.filesUsage.update()
      this.server.respond()
      ok(
        this.filesUsage.setState.calledWith(data),
        'called set state with returned get request data'
      )
    }
  )
})

test('update called after component mounted', function() {
  return this.filesUpdateTest(
    {
      contextType: 'users',
      contextId: 4
    },
    () => {
      sandbox.stub(this.filesUsage, 'update').returns(true)
      this.filesUsage.componentDidMount()
      ok(this.filesUsage.update.calledOnce, 'called update after it mounted')
    }
  )
})
