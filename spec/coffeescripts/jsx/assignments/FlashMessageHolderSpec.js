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
import FlashMessageHolder from 'jsx/assignments/FlashMessageHolder'
import configureStore from 'jsx/assignments/store/configureStore'

QUnit.module('FlashMessageHolder', {
  setup() {
    this.props = {
      time: 123,
      message: '',
      error: false,
      onError() {},
      onSuccess() {}
    }
    this.flashMessageHolder = ReactDOM.render(
      <FlashMessageHolder {...this.props} />,
      document.getElementById('fixtures')
    )
  },
  teardown() {
    this.props = null
    ReactDOM.unmountComponentAtNode(document.getElementById('fixtures'))
  }
})

test('renders nothing', function() {
  ok(ReactDOM.findDOMNode(this.flashMessageHolder) === null, 'nothing was rendered')
})

test('calls proper function when state is an error', function() {
  let called = false
  this.props.error = true
  this.props.message = 'error'
  this.props.time = 125
  this.props.onError = () => (called = true)
  ReactDOM.render(<FlashMessageHolder {...this.props} />, document.getElementById('fixtures'))
  ok(called, 'called error')
})

test('calls proper function when state is not an error', function() {
  let called = false
  this.props.error = false
  this.props.message = 'success'
  this.props.time = 125
  this.props.onSuccess = () => (called = true)
  ReactDOM.render(<FlashMessageHolder {...this.props} />, document.getElementById('fixtures'))
  ok(called, 'called success')
})

test('only updates when the new time is greater than the old time', function() {
  let called = false
  let errCalled = false
  this.props.error = false
  this.props.message = 'random'
  this.props.time = 1
  this.props.onSuccess = () => (called = true)
  this.props.onError = () => (errCalled = true)
  ReactDOM.render(<FlashMessageHolder {...this.props} />, document.getElementById('fixtures'))
  ok(!called, 'did not call the success function')
  ok(!errCalled, 'did not call the error function')
})
