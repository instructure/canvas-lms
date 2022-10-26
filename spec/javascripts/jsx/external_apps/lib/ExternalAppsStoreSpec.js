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

import store from 'ui/features/external_apps/react/lib/ExternalAppsStore'
import fakeENV from 'helpers/fakeENV'

QUnit.module('ExternalApps.ExternalAppsStore', {
  setup() {
    fakeENV.setup({CONTEXT_BASE_URL: '/accounts/1'})
    this.server = sinon.fakeServer.create()
    store.reset()
    this.tools = [
      {
        app_id: 1,
        app_type: 'ContextExternalTool',
        description:
          'Talent provides an online, interactive video platform for professional development',
        enabled: true,
        installed_locally: true,
        name: 'Talent',
        context: 'Course',
        context_id: 1,
      },
      {
        app_id: 2,
        app_type: 'Lti::ToolProxy',
        description: null,
        enabled: true,
        installed_locally: true,
        name: 'Twitter',
        context: 'Course',
        context_id: 1,
      },
      {
        app_id: 3,
        app_type: 'Lti::ToolProxy',
        description: null,
        enabled: false,
        installed_locally: true,
        name: 'LinkedIn',
        context: 'Course',
        context_id: 1,
      },
    ]
    this.accountResponse = {
      id: 1,
      name: 'root',
      workflow_state: 'active',
      parent_account_id: null,
      root_account_id: null,
      default_storage_quota_mb: 500,
      default_user_storage_quota_mb: 50,
      default_group_storage_quota_mb: 50,
      default_time_zone: 'America/Denver',
    }
  },
  teardown() {
    this.server.restore()
    return store.reset()
  },
})

test('fetch', function () {
  this.server.respondWith('GET', /\/lti_apps/, [
    200,
    {'Content-Type': 'application/json'},
    JSON.stringify(this.tools),
  ])
  store.fetch()
  this.server.respond()
  equal(store.getState().externalTools.length, 3)
})

test('resets and fetch responses interwoven', function () {
  this.server.respondWith('GET', /\/lti_apps/, [
    200,
    {'Content-Type': 'application/json'},
    JSON.stringify(this.tools),
  ])
  this.server.respondWith('GET', /\/lti_apps/, [
    200,
    {'Content-Type': 'application/json'},
    JSON.stringify(this.tools),
  ])
  store.fetch()
  store.reset()
  store.fetch()
  this.server.respond()
  this.server.respond()
  equal(store.getState().externalTools.length, 3)
})

test('updateAccessToken', function () {
  this.server.respondWith('PUT', /\/accounts/, [
    200,
    {'Content-Type': 'application/json'},
    JSON.stringify(this.accountResponse),
  ])
  const success = (data, statusText, xhr) => equal(statusText, 'success')
  const error = () => ok(false, 'Unable to update app center access token')
  store.updateAccessToken('/accounts/1', '1234', success.bind(this), error.bind(this))
  return this.server.respond()
})

test('fetchWithDetails with ContextExternalTool', function () {
  expect(1)
  const tool = this.tools[0]
  this.server.respondWith('GET', /\/external_tools/, [
    200,
    {'Content-Type': 'application/json'},
    '{ "status": "ok" }',
  ])
  store.fetchWithDetails(tool).done(data => equal(data.status, 'ok'))
  return this.server.respond()
})

test('fetchWithDetails with Lti::ToolProxy', function () {
  expect(1)
  const tool = this.tools[1]
  this.server.respondWith('GET', /\/tool_proxies/, [
    200,
    {'Content-Type': 'application/json'},
    '{ "status": "ok" }',
  ])
  store.fetchWithDetails(tool).done(data => equal(data.status, 'ok'))
  return this.server.respond()
})

test('save', function () {
  expect(4)
  const {_generateParams} = store
  store._generateParams = () => ({foo: 'bar'})
  const spy = sandbox.spy(store, 'save')
  const data = {some: 'data'}
  const success = function (data, statusText, xhr) {
    equal(statusText, 'success')
    equal(data.status, 'ok')
  }
  const error = () => ok(false, 'Unable to save app')
  this.server.respondWith('POST', /\/external_tools/, [
    200,
    {'Content-Type': 'application/json'},
    '{ "status": "ok" }',
  ])
  store.save('manual', data, success.bind(this), error.bind(this))
  this.server.respond()
  equal(spy.lastCall.args[0], 'manual')
  equal(spy.lastCall.args[1], data)
  store._generateParams = _generateParams
})

test('save stringifys JSON payload', function () {
  const {_generateParams} = store
  const {ajax} = $
  const ajaxSpy = sinon.spy()
  store._generateParams = () => ({
    foo: 'bar',
    url: null,
  })
  const data = {some: 'data'}
  const success = function (data, statusText, xhr) {
    equal(statusText, 'success')
    equal(data.status, 'ok')
  }
  const error = () => ok(false, 'Unable to save app')
  $.ajax = ajaxSpy
  this.server.respondWith('POST', /\/external_tools/, [
    200,
    {'Content-Type': 'application/json'},
    '{ "status": "ok" }',
  ])
  store.save('manual', data, success.bind(this), error.bind(this))
  this.server.respond()
  equal(typeof ajaxSpy.lastCall.args[0].data, 'string')
  store._generateParams = _generateParams
  $.ajax = ajax
})

test('save sets the content type to application/json', function () {
  const {_generateParams} = store
  const {ajax} = $
  const ajaxSpy = sinon.spy()
  store._generateParams = () => ({
    foo: 'bar',
    url: null,
  })
  const data = {some: 'data'}
  const success = function (data, statusText, xhr) {
    equal(statusText, 'success')
    equal(data.status, 'ok')
  }
  const error = () => ok(false, 'Unable to save app')
  $.ajax = ajaxSpy
  this.server.respondWith('POST', /\/external_tools/, [
    200,
    {'Content-Type': 'application/json'},
    '{ "status": "ok" }',
  ])
  store.save('manual', data, success.bind(this), error.bind(this))
  this.server.respond()
  equal(ajaxSpy.lastCall.args[0].contentType, 'application/json')
  store._generateParams = _generateParams
  $.ajax = ajax
})

test('_generateParams manual', () => {
  const data = {
    name: 'My App',
    privacyLevel: 'email_only',
    consumerKey: 'KEY',
    sharedSecret: 'SECRET',
    customFields: 'a=1\nb=2\nc=3',
    url: 'http://google.com',
    description: 'This is a description',
    verifyUniqueness: 'true',
  }
  const params = store._generateParams('manual', data)
  deepEqual(params, {
    consumer_key: 'KEY',
    custom_fields: {
      a: '1',
      b: '2',
      c: '3',
    },
    description: 'This is a description',
    domain: undefined,
    name: 'My App',
    privacy_level: 'email_only',
    shared_secret: 'SECRET',
    url: 'http://google.com',
    verify_uniqueness: 'true',
  })
})

test('_generateParams url', () => {
  const data = {
    name: 'My App',
    configUrl: 'http://example.com/config.xml',
    verifyUniqueness: 'true',
  }
  const params = store._generateParams('url', data)
  deepEqual(params, {
    config_type: 'by_url',
    config_url: 'http://example.com/config.xml',
    consumer_key: 'N/A',
    name: 'My App',
    privacy_level: 'anonymous',
    shared_secret: 'N/A',
    verify_uniqueness: 'true',
  })
})

test('_generateParams xml', () => {
  const data = {
    name: 'My App',
    xml: '<foo>bar</foo>',
    verifyUniqueness: 'true',
  }
  const params = store._generateParams('xml', data)
  deepEqual(params, {
    config_type: 'by_xml',
    config_xml: '<foo>bar</foo>',
    consumer_key: 'N/A',
    name: 'My App',
    privacy_level: 'anonymous',
    shared_secret: 'N/A',
    verify_uniqueness: 'true',
  })
})

test('delete ContextExternalTool', function () {
  expect(4)
  store.setState({externalTools: this.tools})
  const tool = this.tools[0]
  const success = function (data, statusText, xhr) {
    equal(statusText, 'success')
    equal(data.status, 'ok')
  }
  const error = () => ok(false, 'Unable to save app')
  const {_deleteSuccessHandler} = store
  const {_deleteErrorHandler} = store
  store._deleteSuccessHandler = success
  store._deleteErrorHandler = error
  equal(store.getState().externalTools.length, 3)
  this.server.respondWith('DELETE', /\/external_tools/, [
    200,
    {'Content-Type': 'application/json'},
    '{ "status": "ok" }',
  ])
  store.delete(tool)
  this.server.respond()
  equal(store.getState().externalTools.length, 2)
  store._deleteSuccessHandler = _deleteSuccessHandler
  store._deleteErrorHandler = _deleteErrorHandler
})

test('delete Lti::ToolProxy', function () {
  expect(4)
  store.setState({externalTools: this.tools})
  const tool = this.tools[1]
  const success = function (data, statusText, xhr) {
    equal(statusText, 'success')
    equal(data.status, 'ok')
  }
  const error = () => ok(false, 'Unable to save app')
  const {_deleteSuccessHandler} = store
  const {_deleteErrorHandler} = store
  store._deleteSuccessHandler = success
  store._deleteErrorHandler = error
  equal(store.getState().externalTools.length, 3)
  this.server.respondWith('DELETE', /\/tool_proxies/, [
    200,
    {'Content-Type': 'application/json'},
    '{ "status": "ok" }',
  ])
  store.delete(tool)
  this.server.respond()
  equal(store.getState().externalTools.length, 2)
  store._deleteSuccessHandler = _deleteSuccessHandler
  store._deleteErrorHandler = _deleteErrorHandler
})

test('deactivate', function () {
  expect(4)
  store.setState({externalTools: this.tools})
  const tool = this.tools[1]
  const success = function (data, statusText, xhr) {
    equal(statusText, 'success')
    equal(data.status, 'ok')
  }
  const error = () => ok(false, 'Unable to save app')
  ok(store.getState().externalTools[1].enabled)
  this.server.respondWith('PUT', /\/tool_proxies/, [
    200,
    {'Content-Type': 'application/json'},
    '{ "status": "ok" }',
  ])
  store.deactivate(tool, success, error)
  this.server.respond()
  const updatedTool = store.findById(tool.app_id)
  equal(updatedTool.enabled, false)
})

test('findById', function () {
  store.setState({externalTools: this.tools})
  const tool = store.findById(3)
  equal(tool.name, 'LinkedIn')
})
