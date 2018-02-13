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
  'jsx/external_apps/components/ConfigurationFormXml'
], (React, ReactDOM, TestUtils, ConfigurationFormXml) ->

  Simulate = TestUtils.Simulate
  wrapper = document.getElementById('fixtures')

  createElement = (data) ->
    React.createElement(ConfigurationFormXml, {
      name: data.name
      consumerKey: data.consumerKey
      sharedSecret: data.sharedSecret
      xml: data.xml
    })

  renderComponent = (data) ->
    ReactDOM.render(createElement(data), wrapper)

  QUnit.module 'ExternalApps.ConfigurationFormXml',
    teardown: ->
      ReactDOM.unmountComponentAtNode wrapper

  test 'isValid when not valid', ->
    data =
      name: ''
      consumerKey: ''
      sharedSecret: ''
      xml: ''
    component = renderComponent(data)
    ok !component.isValid()
    deepEqual component.state.errors, {
      name: 'This field is required'
      xml: 'This field is required'
    }

  test 'isValid when valid', ->
    data =
      name: 'My App'
      consumerKey: 'A'
      sharedSecret: 'B'
      xml: '<foo>bar</foo>'
    component = renderComponent(data)
    component.isValid()
    deepEqual component.state.errors, {}

  test 'sets verifyUniqueness to true', ->
    data =
      name: 'My App'
      consumerKey: 'A'
      sharedSecret: 'B'
      xml: '<foo>bar</foo>'
    expectedData =
      name: 'My App'
      consumerKey: 'A'
      sharedSecret: 'B'
      xml: '<foo>bar</foo>'
      verifyUniqueness: 'true'
    component = renderComponent(data)
    deepEqual component.getFormData(), expectedData
