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

import INST from 'INST'
import $ from 'jquery'
import 'jquery.ajaxJSON'
import sinon from 'sinon'

let storedInstEnv = null

QUnit.module('$.fn.defaultAjaxError', {
  setup() {
    storedInstEnv = INST.environment
    $.ajaxJSON.unhandledXHRs = []
  },
  teardown() {
    INST.environment = storedInstEnv
  }
})

test('should call the function if not production', function() {
  notEqual(INST.environment, 'production')
  deepEqual($.ajaxJSON.unhandledXHRs, [])
  const spy = sinon.spy()
  $('#fixtures').defaultAjaxError(spy)
  const xhr = {
    status: 200,
    responseText: '{"status": "ok"}'
  }
  $.fn.defaultAjaxError.func({}, xhr)
  ok(spy.called)
})

test('should call the function if unhandled', function() {
  INST.environment = 'production'
  const xhr = {
    status: 400,
    responseText: '{"status": "ok"}'
  }
  $.ajaxJSON.unhandledXHRs.push(xhr)
  const spy = sinon.spy()
  $('#fixtures').defaultAjaxError(spy)
  $.fn.defaultAjaxError.func({}, xhr)
  ok(spy.called)
})

test('should call the function if unauthenticated', function() {
  INST.environment = 'production'
  deepEqual($.ajaxJSON.unhandledXHRs, [])
  const spy = sinon.spy()
  $('#fixtures').defaultAjaxError(spy)
  const xhr = {
    status: 401,
    responseText: '{"status": "unauthenticated"}'
  }
  $.fn.defaultAjaxError.func({}, xhr)
  ok(spy.called)
})

QUnit.module('$.ajaxJSON.isUnauthenticated')

test('returns false if status is not 401', () =>
  equal($.ajaxJSON.isUnauthenticated({status: 200}), false))

test('returns false if status is 401 but the message is not unauthenticated', () => {
  const xhr = {
    status: 401,
    responseText: ''
  }
  equal($.ajaxJSON.isUnauthenticated(xhr), false)
})

test('returns false if status is 401 but the message is not unauthenticated', () => {
  const xhr = {
    status: 401,
    responseText: '{"status": "unauthorized"}'
  }
  equal($.ajaxJSON.isUnauthenticated(xhr), false)
})

test('returns true if status is 401 and message is unauthenticated', () => {
  const xhr = {
    status: 401,
    responseText: '{"status": "unauthenticated"}'
  }
  equal($.ajaxJSON.isUnauthenticated(xhr), true)
})

let abortXhr

QUnit.module('$.ajaxJSON.abortRequest', {
  setup () {
    abortXhr = {
      readyState: 0,
      abort: sinon.spy()
    }
  }
})

test('aborts xhr if not done', () => {
  $.ajaxJSON.abortRequest(abortXhr)
  ok(abortXhr.abort.called)
})

test('does nothing if xhr is done', () => {
  abortXhr.readyState = 4
  $.ajaxJSON.abortRequest(abortXhr)
  ok(abortXhr.abort.notCalled)
})

test('does not throw if called with null or undefined', () => {
  $.ajaxJSON.abortRequest(null)
  $.ajaxJSON.abortRequest(undefined)
  ok(true) // required assertion
})

test('does not call success or error handler', () => {
  const fakeXhr = sinon.useFakeXMLHttpRequest()
  let xhr
  fakeXhr.onCreate = _xhr => {
    xhr = _xhr
    const _abort = xhr.abort
    xhr.abort = () => {
      xhr.statusText = 'abort'
      _abort.call(xhr)
    }
  }
  const spy = sinon.spy()
  $.ajaxJSON('/api', 'GET', {}, spy, spy)
  $.ajaxJSON.abortRequest(xhr)
  xhr.readyStateChange(sinon.FakeXMLHttpRequest.DONE);
  fakeXhr.restore()
  ok(spy.notCalled)
})
