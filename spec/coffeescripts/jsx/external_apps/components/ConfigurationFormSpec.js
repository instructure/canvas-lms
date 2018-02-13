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
  'jsx/external_apps/components/ConfigurationForm'
], (React, ReactDOM, TestUtils, ConfigurationForm) ->

  Simulate = TestUtils.Simulate
  wrapper = document.getElementById('fixtures')

  handleSubmit = ->
    ok true, 'handleSubmit called successfully'

  createElement = (data) ->
    React.createElement(ConfigurationForm, {
      configurationType: data.configurationType
      handleSubmit: data.handleSubmit
      tool: data.tool
      showConfigurationSelector: data.showConfigurationSelector
    })

  renderComponent = (data) ->
    ReactDOM.render(createElement(data), wrapper)

  getDOMNodes = (data) ->
    component = renderComponent(data)
    {
      component: component
      configurationFormManual: component.refs.configurationFormManual?.getDOMNode()
      configurationFormUrl: component.refs.configurationFormUrl?.getDOMNode()
      configurationFormXml: component.refs.configurationFormXml?.getDOMNode()
      configurationFormLti2: component.refs.configurationFormLti2?.getDOMNode()
      configurationTypeSelector: component.refs.configurationTypeSelector?.getDOMNode()
      submitLti2: component.refs.submitLti2?.getDOMNode()
      submit: component.refs.submit?.getDOMNode()
    }

  QUnit.module 'ExternalApps.ConfigurationForm',
    teardown: ->
      ReactDOM.unmountComponentAtNode wrapper

  test 'renders manual form with new tool', ->
    data =
      configurationType: 'manual'
      handleSubmit: handleSubmit
      tool: {}
      showConfigurationSelector: true
    nodes = getDOMNodes(data)
    ok nodes.component.isMounted()
    ok TestUtils.isCompositeComponentWithType(nodes.component, ConfigurationForm)
    ok nodes.configurationTypeSelector
    ok nodes.configurationFormManual

  test 'renders url form with new tool', ->
    data =
      configurationType: 'url'
      handleSubmit: handleSubmit
      tool: {}
      showConfigurationSelector: true
    nodes = getDOMNodes(data)
    ok nodes.configurationTypeSelector
    ok nodes.configurationFormUrl

  test 'renders xml form with new tool', ->
    data =
      configurationType: 'xml'
      handleSubmit: handleSubmit
      tool: {}
      showConfigurationSelector: true
    nodes = getDOMNodes(data)
    ok nodes.configurationTypeSelector
    ok nodes.configurationFormXml

  test 'renders lti2 form with new tool', ->
    data =
      configurationType: 'lti2'
      handleSubmit: handleSubmit
      tool: {}
      showConfigurationSelector: true
    nodes = getDOMNodes(data)
    ok nodes.configurationTypeSelector
    ok nodes.configurationFormLti2

  test 'renders manual form with existing tool and no selector', ->
    data =
      configurationType: 'manual'
      handleSubmit: handleSubmit
      tool: {
        name          : 'My App'
        consumerKey   : 'KEY'
        sharedSecret  : 'SECRET'
        url           : 'http://example.com'
        domain        : ''
        privacy_level : 'anonymous'
        customFields  : { a: 1, b: 2, c: 3 }
        description   : 'My super awesome example app'
      }
      showConfigurationSelector: false
    nodes = getDOMNodes(data)
    ok nodes.configurationFormManual
    ok !nodes.configurationTypeSelector

  test 'saves manual form with trimmed props', ->
    handleSubmitSpy = sinon.spy()
    data =
      configurationType: 'manual'
      handleSubmit: handleSubmitSpy
      tool: {
        name           : '  My App'
        consumer_key   : 'key  '
        shared_secret  : '  secret'
        url            : '\u0009http://example.com  '
        domain         : ''
        privacy_level  : 'anonymous'
        custom_fields  : { a: 1, b: 2, c: 3 }
        description    : '\u0009My super awesome example app'
      }
      showConfigurationSelector: true
    component = renderComponent(data)
    e = {
      type: 'click',
      preventDefault: sinon.stub()
    }
    component.handleSubmit(e)
    formData = handleSubmitSpy.getCall(0).args[1]
    handleSubmitSpy.reset()
    strictEqual formData.name, 'My App'
    strictEqual formData.consumerKey, 'key'
    strictEqual formData.sharedSecret, 'secret'
    strictEqual formData.url, 'http://example.com'
    strictEqual formData.domain, ''
    strictEqual formData.description, 'My super awesome example app'

  test 'saves url form with trimmed props', ->
    handleSubmitSpy = sinon.spy()
    data =
      configurationType: 'url'
      handleSubmit: handleSubmitSpy
      tool: {
        name           : '  My App'
        consumer_key   : 'key  '
        shared_secret  : '  secret'
        config_url     : '\u0009http://example.com  '
      }
      showConfigurationSelector: true
    component = renderComponent(data)
    e = {
      type: 'click',
      preventDefault: sinon.stub()
    }
    component.handleSubmit(e)
    formData = handleSubmitSpy.getCall(0).args[1]
    handleSubmitSpy.reset()
    strictEqual formData.name, 'My App'
    strictEqual formData.consumerKey, 'key'
    strictEqual formData.sharedSecret, 'secret'
    strictEqual formData.configUrl, 'http://example.com'

  test 'saves xml form with trimmed props', ->
    handleSubmitSpy = sinon.spy()
    data =
      configurationType: 'xml'
      handleSubmit: handleSubmitSpy
      tool: {
        name           : '  My App'
        consumer_key   : 'key   '
        shared_secret  : '   secret'
        xml            : '\u0009 some xml  '
      }
      showConfigurationSelector: true
    component = renderComponent(data)
    e = {
      type: 'click',
      preventDefault: sinon.stub()
    }
    component.handleSubmit(e)
    formData = handleSubmitSpy.getCall(0).args[1]
    handleSubmitSpy.reset()
    strictEqual formData.name, 'My App'
    strictEqual formData.consumerKey, 'key'
    strictEqual formData.sharedSecret, 'secret'
    strictEqual formData.xml, 'some xml'

  test 'saves lti2 form with trimmed props', ->
    handleSubmitSpy = sinon.spy()
    data =
      configurationType: 'lti2'
      handleSubmit: handleSubmitSpy
      tool: {
        registration_url: '\u0009https://lti-tool-provider-example..com/register '
      }
      showConfigurationSelector: true
    component = renderComponent(data)
    e = {
      type: 'click',
      preventDefault: sinon.stub()
    }
    component.handleSubmit(e)
    formData = handleSubmitSpy.getCall(0).args[1]
    handleSubmitSpy.reset()
    strictEqual formData.registrationUrl, 'https://lti-tool-provider-example..com/register'

  test "'iframeTarget' returns null if configuration type is not lti2", ->
    data =
      configurationType: 'manual'
      handleSubmit: handleSubmit
      tool: {}
      showConfigurationSelector: true
    nodes = getDOMNodes(data)
    equal nodes.component.iframeTarget(), null

  test "'iframeTarget' returns 'lti2_registration_frame' if configuration type is lti2", ->
    data =
      configurationType: 'lti2'
      handleSubmit: handleSubmit
      tool: {}
      showConfigurationSelector: true
    nodes = getDOMNodes(data)
    equal nodes.component.iframeTarget(), 'lti2_registration_frame'

  test "sets the target of the form to the iframe for lti2", ->
    data =
      configurationType: 'lti2'
      handleSubmit: handleSubmit
      tool: {}
      showConfigurationSelector: true
    nodes = getDOMNodes(data)
    equal document.querySelector('form').getAttribute('target'), 'lti2_registration_frame'

  test "sets the form method to post", ->
    data =
      configurationType: 'lti2'
      handleSubmit: handleSubmit
      tool: {}
      showConfigurationSelector: true
    nodes = getDOMNodes(data)
    equal document.querySelector('form').getAttribute('method'), 'post'
