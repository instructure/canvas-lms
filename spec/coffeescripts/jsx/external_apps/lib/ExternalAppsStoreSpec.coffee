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
  'jsx/external_apps/lib/ExternalAppsStore',
  'helpers/fakeENV'
], (store, fakeENV) ->
  QUnit.module 'ExternalApps.ExternalAppsStore',
    setup: ->
      fakeENV.setup({
        CONTEXT_BASE_URL: "/accounts/1"
      })
      @server = sinon.fakeServer.create()
      store.reset()
      @tools = [
        {
          "app_id": 1,
          "app_type": "ContextExternalTool",
          "description": "Talent provides an online, interactive video platform for professional development",
          "enabled": true,
          "installed_locally": true,
          "name": "Talent",
          "context": "Course",
          "context_id": 1
        },
        {
          "app_id": 2,
          "app_type": "Lti::ToolProxy",
          "description": null,
          "enabled": true,
          "installed_locally": true,
          "name": "Twitter",
          "context": "Course",
          "context_id": 1
        },
        {
          "app_id": 3,
          "app_type": "Lti::ToolProxy",
          "description": null,
          "enabled": false,
          "installed_locally": true,
          "name": "LinkedIn",
          "context": "Course",
          "context_id": 1
        }
      ]
      @accountResponse = {
        "id": 1,
        "name": "root",
        "workflow_state": "active",
        "parent_account_id": null,
        "root_account_id": null,
        "default_storage_quota_mb": 500,
        "default_user_storage_quota_mb": 50,
        "default_group_storage_quota_mb": 50,
        "default_time_zone": "America/Denver"
      }

    teardown: ->
      @server.restore()
      store.reset()

  test 'fetch', ->
    @server.respondWith "GET", /\/lti_apps/, [200, { "Content-Type": "application/json" }, JSON.stringify(@tools)]
    store.fetch()
    @server.respond()
    equal store.getState().externalTools.length, 3

  test 'updateAccessToken', ->
    @server.respondWith 'PUT', /\/accounts/, [200, { 'Content-Type': 'application/json' }, JSON.stringify(@accountResponse)]
    success = (data, statusText, xhr) ->
      equal statusText, 'success'
    error = ->
      ok false, 'Unable to update app center access token'
    store.updateAccessToken('/accounts/1', '1234', success.bind(this), error.bind(this))
    @server.respond()

  test 'fetchWithDetails with ContextExternalTool', ->
    expect 1
    tool = @tools[0]
    @server.respondWith "GET", /\/external_tools/, [200, { "Content-Type": "application/json" }, '{ "status": "ok" }' ]
    store.fetchWithDetails(tool).done (data)->
      equal data.status, 'ok'
    @server.respond()

  test 'fetchWithDetails with Lti::ToolProxy', ->
    expect 1
    tool = @tools[1]
    @server.respondWith "GET", /\/tool_proxies/, [200, { "Content-Type": "application/json" }, '{ "status": "ok" }' ]
    store.fetchWithDetails(tool).done (data)->
      equal data.status, 'ok'
    @server.respond()

  test 'save', ->
    expect 4

    _generateParams = store._generateParams
    store._generateParams = ->
      return {
        foo: 'bar'
      }

    spy = @spy(store, 'save')
    data = { some: 'data' }

    success = (data, statusText, xhr)->
      equal statusText, 'success'
      equal data.status, 'ok'
    error = ->
      ok false, 'Unable to save app'

    @server.respondWith "POST", /\/external_tools/, [200, { "Content-Type": "application/json" }, '{ "status": "ok" }' ]
    store.save('manual', data, success.bind(this), error.bind(this))
    @server.respond()

    equal spy.lastCall.args[0], 'manual'
    equal spy.lastCall.args[1], data

    store._generateParams = _generateParams

  test '_generateParams manual', ->
    data =
      name: 'My App'
      privacyLevel: 'email_only'
      consumerKey: 'KEY'
      sharedSecret: 'SECRET'
      customFields: "a=1\nb=2\nc=3"
      url: 'http://google.com'
      description: 'This is a description'
    params = store._generateParams('manual', data)
    deepEqual params, {
      consumer_key: "KEY"
      "custom_fields[a]": "1"
      "custom_fields[b]": "2"
      "custom_fields[c]": "3"
      description: "This is a description"
      domain: undefined
      name: "My App"
      privacy_level: "email_only"
      shared_secret: "SECRET"
      url: "http://google.com"
    }

  test '_generateParams url', ->
    data =
      name: 'My App'
      configUrl: 'http://example.com/config.xml'
    params = store._generateParams('url', data)
    deepEqual params, {
      config_type: "by_url"
      config_url: "http://example.com/config.xml"
      consumer_key: "N/A"
      name: "My App"
      privacy_level: "anonymous"
      shared_secret: "N/A"
    }

  test '_generateParams xml', ->
    data =
      name: 'My App'
      xml: '<foo>bar</foo>'
    params = store._generateParams('xml', data)
    deepEqual params, {
      config_type: "by_xml"
      config_xml: "<foo>bar</foo>"
      consumer_key: "N/A"
      name: "My App"
      privacy_level: "anonymous"
      shared_secret: "N/A"
    }

  test 'delete ContextExternalTool', ->
    expect 4

    store.setState({ externalTools: @tools })
    tool = @tools[0]

    success = (data, statusText, xhr)->
      equal statusText, 'success'
      equal data.status, 'ok'
    error = ->
      ok false, 'Unable to save app'

    _deleteSuccessHandler = store._deleteSuccessHandler
    _deleteErrorHandler = store._deleteErrorHandler
    store._deleteSuccessHandler = success
    store._deleteErrorHandler = error

    equal store.getState().externalTools.length, 3

    @server.respondWith "DELETE", /\/external_tools/, [200, { "Content-Type": "application/json" }, '{ "status": "ok" }' ]
    store.delete(tool)
    @server.respond()

    equal store.getState().externalTools.length, 2

    store._deleteSuccessHandler = _deleteSuccessHandler
    store._deleteErrorHandler = _deleteErrorHandler

  test 'delete Lti::ToolProxy', ->
    expect 4

    store.setState({ externalTools: @tools })
    tool = @tools[1]

    success = (data, statusText, xhr)->
      equal statusText, 'success'
      equal data.status, 'ok'
    error = ->
      ok false, 'Unable to save app'

    _deleteSuccessHandler = store._deleteSuccessHandler
    _deleteErrorHandler = store._deleteErrorHandler
    store._deleteSuccessHandler = success
    store._deleteErrorHandler = error

    equal store.getState().externalTools.length, 3

    @server.respondWith "DELETE", /\/tool_proxies/, [200, { "Content-Type": "application/json" }, '{ "status": "ok" }' ]
    store.delete(tool)
    @server.respond()

    equal store.getState().externalTools.length, 2

    store._deleteSuccessHandler = _deleteSuccessHandler
    store._deleteErrorHandler = _deleteErrorHandler

  test 'deactivate', ->
    expect 4

    store.setState({ externalTools: @tools })
    tool = @tools[1]

    success = (data, statusText, xhr)->
      equal statusText, 'success'
      equal data.status, 'ok'
    error = ->
      ok false, 'Unable to save app'

    ok store.getState().externalTools[1].enabled

    @server.respondWith "PUT", /\/tool_proxies/, [200, { "Content-Type": "application/json" }, '{ "status": "ok" }' ]
    store.deactivate(tool, success, error)
    @server.respond()

    updatedTool = store.findById(tool.app_id)
    equal updatedTool.enabled, false

  test 'findById', ->
    store.setState({ externalTools: @tools })
    tool = store.findById(3)
    equal tool.name, 'LinkedIn'
