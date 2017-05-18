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
  'jquery'
  'react'
  'react-dom'
  'react-addons-test-utils'
  'jsx/external_apps/components/Lti2Iframe'
], ($, React, ReactDOM, TestUtils, Lti2Iframe) ->

  Simulate = TestUtils.Simulate
  wrapper = document.getElementById('fixtures')

  createElement = (data) ->
    React.createElement(Lti2Iframe, {
      registrationUrl: data.registrationUrl
      handleInstall: data.handleInstall
    })

  renderComponent = (data) ->
    ReactDOM.render(createElement(data), wrapper)

  QUnit.module 'ExternalApps.Lti2Iframe',
    teardown: ->
      ReactDOM.unmountComponentAtNode wrapper

  test 'renders', ->
    data =
      registrationUrl: 'http://example.com'
      handleInstall: ->
    component = renderComponent(data)
    ok component.isMounted()
    ok TestUtils.isCompositeComponentWithType(component, Lti2Iframe)

  test 'renders any children after the iframe', ->
    element = React.createElement(Lti2Iframe,{
      registrationUrl: 'http://www.test.com',
      handleInstall: ->
    }, React.createElement('div', {id: 'test-child'}))
    component = TestUtils.renderIntoDocument(element)
    ok $(component.getDOMNode()).find('#test-child').length == 1


