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
import FilesUsage from '../FilesUsage'
import sinon from 'sinon'

const sandbox = sinon.createSandbox()

let server
let filesUsage

function filesUpdateTest(props, test) {
  server = sinon.fakeServer.create()
  filesUsage = TestUtils.renderIntoDocument(<FilesUsage {...props} />)
  test()
  ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(filesUsage).parentNode)
  server.restore()
}

describe('FilesUsage#update', () => {
  test('makes a get request with contextType and contextId', function (done) {
    sandbox.stub($, 'get')
    filesUpdateTest(
      {
        contextType: 'users',
        contextId: 4,
      },
      () => {
        filesUsage.update()
        // 'makes get request with correct params'
        expect($.get.calledWith(filesUsage.url())).toBeTruthy()
        done()
      }
    )
  })

  // passes in QUnit, fails in Jest
  test.skip('sets state with ajax requests returned data', function (done) {
    const data = {foo: 'bar'}
    return filesUpdateTest(
      {
        contextType: 'users',
        contextId: 4,
      },
      () => {
        server.respondWith(filesUsage.url(), [
          200,
          {'Content-Type': 'application/json'},
          JSON.stringify(data),
        ])
        sandbox.spy(filesUsage, 'setState')
        filesUsage.update()
        server.respond()
        // 'called set state with returned get request data'
        expect(filesUsage.setState.calledWith(data)).toBeTruthy()
        done()
      }
    )
  })

  test('update called after component mounted', function () {
    return filesUpdateTest(
      {
        contextType: 'users',
        contextId: 4,
      },
      () => {
        sandbox.stub(filesUsage, 'update').returns(true)
        filesUsage.componentDidMount()
        // 'called update after it mounted'
        expect(filesUsage.update.calledOnce).toBeTruthy()
      }
    )
  })
})
