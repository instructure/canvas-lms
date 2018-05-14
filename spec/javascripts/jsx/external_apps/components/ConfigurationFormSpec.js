/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import TestUtils from 'react-addons-test-utils'
import ConfigurationForm from 'jsx/external_apps/components/ConfigurationForm'

const wrapper = document.getElementById('fixtures')

const handleSubmit = () => ok(true, 'handleSubmit called successfully')

const createElement = data => (
  <ConfigurationForm
    configurationType={data.configurationType}
    handleSubmit={data.handleSubmit}
    tool={data.tool}
    showConfigurationSelector={data.showConfigurationSelector}
  />
)

const renderComponent = data => ReactDOM.render(createElement(data), wrapper)

const getDOMNodes = function(data) {
  const component = renderComponent(data)
  return {
    component,
    configurationFormManual: component.refs.configurationFormManual,
    configurationFormUrl: component.refs.configurationFormUrl,
    configurationFormXml: component.refs.configurationFormXml,
    configurationFormLti2: component.refs.configurationFormLti2,
    configurationTypeSelector: component.refs.configurationTypeSelector,
    submitLti2: component.refs.submitLti2,
    submit: component.refs.submit
  }
}

QUnit.module('ExternalApps.ConfigurationForm', {
  teardown() {
    ReactDOM.unmountComponentAtNode(wrapper)
  }
})

test('renders manual form with new tool', () => {
  const data = {
    configurationType: 'manual',
    handleSubmit,
    tool: {},
    showConfigurationSelector: true
  }
  const nodes = getDOMNodes(data)
  ok(nodes.component.isMounted())
  ok(TestUtils.isCompositeComponentWithType(nodes.component, ConfigurationForm))
  ok(nodes.configurationTypeSelector)
  ok(nodes.configurationFormManual)
})

test('renders url form with new tool', () => {
  const data = {
    configurationType: 'url',
    handleSubmit,
    tool: {},
    showConfigurationSelector: true
  }
  const nodes = getDOMNodes(data)
  ok(nodes.configurationTypeSelector)
  ok(nodes.configurationFormUrl)
})

test('renders xml form with new tool', () => {
  const data = {
    configurationType: 'xml',
    handleSubmit,
    tool: {},
    showConfigurationSelector: true
  }
  const nodes = getDOMNodes(data)
  ok(nodes.configurationTypeSelector)
  ok(nodes.configurationFormXml)
})

test('renders lti2 form with new tool', () => {
  const data = {
    configurationType: 'lti2',
    handleSubmit,
    tool: {},
    showConfigurationSelector: true
  }
  const nodes = getDOMNodes(data)
  ok(nodes.configurationTypeSelector)
  ok(nodes.configurationFormLti2)
})

test('renders manual form with existing tool and no selector', () => {
  const data = {
    configurationType: 'manual',
    handleSubmit,
    tool: {
      name: 'My App',
      consumerKey: 'KEY',
      sharedSecret: 'SECRET',
      url: 'http://example.com',
      domain: '',
      privacy_level: 'anonymous',
      customFields: {a: 1, b: 2, c: 3},
      description: 'My super awesome example app'
    },
    showConfigurationSelector: false
  }
  const nodes = getDOMNodes(data)
  ok(nodes.configurationFormManual)
  ok(!nodes.configurationTypeSelector)
})

test('saves manual form with trimmed props', () => {
  const handleSubmitSpy = sinon.spy()
  const data = {
    configurationType: 'manual',
    handleSubmit: handleSubmitSpy,
    tool: {
      name: '  My App',
      consumer_key: 'key  ',
      shared_secret: '  secret',
      url: '\thttp://example.com  ',
      domain: '',
      privacy_level: 'anonymous',
      custom_fields: {a: 1, b: 2, c: 3},
      description: '\tMy super awesome example app'
    },
    showConfigurationSelector: true
  }
  const component = renderComponent(data)
  const e = {
    type: 'click',
    preventDefault: sinon.stub()
  }
  component.handleSubmit(e)
  const formData = handleSubmitSpy.getCall(0).args[1]
  handleSubmitSpy.reset()
  strictEqual(formData.name, 'My App')
  strictEqual(formData.consumerKey, 'key')
  strictEqual(formData.sharedSecret, 'secret')
  strictEqual(formData.url, 'http://example.com')
  strictEqual(formData.domain, '')
  strictEqual(formData.description, 'My super awesome example app')
})

test('saves url form with trimmed props', () => {
  const handleSubmitSpy = sinon.spy()
  const data = {
    configurationType: 'url',
    handleSubmit: handleSubmitSpy,
    tool: {
      name: '  My App',
      consumer_key: 'key  ',
      shared_secret: '  secret',
      config_url: '\thttp://example.com  '
    },
    showConfigurationSelector: true
  }
  const component = renderComponent(data)
  const e = {
    type: 'click',
    preventDefault: sinon.stub()
  }
  component.handleSubmit(e)
  const formData = handleSubmitSpy.getCall(0).args[1]
  handleSubmitSpy.reset()
  strictEqual(formData.name, 'My App')
  strictEqual(formData.consumerKey, 'key')
  strictEqual(formData.sharedSecret, 'secret')
  strictEqual(formData.configUrl, 'http://example.com')
})

test('saves xml form with trimmed props', () => {
  const handleSubmitSpy = sinon.spy()
  const data = {
    configurationType: 'xml',
    handleSubmit: handleSubmitSpy,
    tool: {
      name: '  My App',
      consumer_key: 'key   ',
      shared_secret: '   secret',
      xml: '\t some xml  '
    },
    showConfigurationSelector: true
  }
  const component = renderComponent(data)
  const e = {
    type: 'click',
    preventDefault: sinon.stub()
  }
  component.handleSubmit(e)
  const formData = handleSubmitSpy.getCall(0).args[1]
  handleSubmitSpy.reset()
  strictEqual(formData.name, 'My App')
  strictEqual(formData.consumerKey, 'key')
  strictEqual(formData.sharedSecret, 'secret')
  strictEqual(formData.xml, 'some xml')
})

test('saves lti2 form with trimmed props', () => {
  const handleSubmitSpy = sinon.spy()
  const data = {
    configurationType: 'lti2',
    handleSubmit: handleSubmitSpy,
    tool: {registration_url: '\thttps://lti-tool-provider-example..com/register '},
    showConfigurationSelector: true
  }
  const component = renderComponent(data)
  const e = {
    type: 'click',
    preventDefault: sinon.stub()
  }
  component.handleSubmit(e)
  const formData = handleSubmitSpy.getCall(0).args[1]
  handleSubmitSpy.reset()
  strictEqual(formData.registrationUrl, 'https://lti-tool-provider-example..com/register')
})

test("'iframeTarget' returns null if configuration type is not lti2", () => {
  const data = {
    configurationType: 'manual',
    handleSubmit,
    tool: {},
    showConfigurationSelector: true
  }
  const nodes = getDOMNodes(data)
  equal(nodes.component.iframeTarget(), null)
})

test("'iframeTarget' returns 'lti2_registration_frame' if configuration type is lti2", () => {
  const data = {
    configurationType: 'lti2',
    handleSubmit,
    tool: {},
    showConfigurationSelector: true
  }
  const nodes = getDOMNodes(data)
  equal(nodes.component.iframeTarget(), 'lti2_registration_frame')
})

test('sets the target of the form to the iframe for lti2', () => {
  const data = {
    configurationType: 'lti2',
    handleSubmit,
    tool: {},
    showConfigurationSelector: true
  }
  const nodes = getDOMNodes(data)
  equal(document.querySelector('form').getAttribute('target'), 'lti2_registration_frame')
})

test('sets the form method to post', () => {
  const data = {
    configurationType: 'lti2',
    handleSubmit,
    tool: {},
    showConfigurationSelector: true
  }
  const nodes = getDOMNodes(data)
  equal(document.querySelector('form').getAttribute('method'), 'post')
})


QUnit.module('ConfigurationForm#defaultState');

test('returns object where allow_membership_service_access is false', () => {
  const component = TestUtils.renderIntoDocument (
    <ConfigurationForm
      handleSubmit={() => {}}
      tool={{}}
      configurationType='manual' />
  );
  const app = TestUtils.findRenderedComponentWithType(component, ConfigurationForm);
  equal(app.defaultState().allow_membership_service_access, false);
});

QUnit.module('ConfigurationForm#reset');

test('resets internal state of component', () => {
  const component = TestUtils.renderIntoDocument (
    <ConfigurationForm
      handleSubmit={() => {}}
      tool={{}}
      configurationType='goofy'
      showConfigurationSelector={true} />
  );
  const app = TestUtils.findRenderedComponentWithType(component, ConfigurationForm);
  app.reset()
  deepEqual(app.state, {
    configurationType: 'goofy',
    showConfigurationSelector: true,
    name: '',
    consumerKey: '',
    sharedSecret: '',
    url: '',
    domain: '',
    privacy_level: '',
    customFields: {},
    description: '',
    configUrl: '',
    registrationUrl: '',
    xml: '',
    allow_membership_service_access: false
  });
});


QUnit.module('ConfigurationForm#defaultState');

test('returns a default state', () => {
  const component = TestUtils.renderIntoDocument (
    <ConfigurationForm
      handleSubmit={() => {}}
      tool={{}}
      configurationType='goofy'
      showConfigurationSelector={true} />
  );
  const app = TestUtils.findRenderedComponentWithType(component, ConfigurationForm);
  app.reset()
  deepEqual(app.defaultState(), {
    configurationType: 'goofy',
    showConfigurationSelector: true,
    name: '',
    consumerKey: '',
    sharedSecret: '',
    url: '',
    domain: '',
    privacy_level: '',
    customFields: {},
    description: '',
    configUrl: '',
    registrationUrl: '',
    xml: '',
    allow_membership_service_access: false
  });
});
