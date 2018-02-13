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
import TestUtils from 'react-addons-test-utils'
import Modal from 'react-modal'
import AddApp from 'jsx/external_apps/components/AddApp'

const {Simulate} = TestUtils
const wrapper = document.getElementById('fixtures')
Modal.setAppElement(wrapper)
const handleToolInstalled = () => ok(true, 'handleToolInstalled called successfully')
const createElement = data => (
  <AddApp handleToolInstalled={data.handleToolInstalled} app={data.app} />
)
const renderComponent = data => ReactDOM.render(createElement(data), wrapper)
const getDOMNodes = function(data) {
  const component = renderComponent(data)
  const addToolButtonNode =
    component.refs.addTool != null ? component.refs.addTool.getDOMNode() : undefined
  const modalNode = component.refs.modal != null ? component.refs.modal.getDOMNode() : undefined
  return [component, addToolButtonNode, modalNode]
}

QUnit.module('ExternalApps.AddApp', {
  setup() {
    this.app = {
      config_options: [],
      config_xml_url: 'https://www.eduappcenter.com/configurations/g7lthtepu68qhchz.xml',
      description: 'Acclaim is the easiest way to organize and annotate videos for class.',
      id: 289,
      is_installed: false,
      name: 'Acclaim',
      requires_secret: true,
      short_name: 'acclaim_app',
      status: 'active'
    }
  },
  teardown() {
    ReactDOM.unmountComponentAtNode(wrapper)
  }
})

test('renders', function() {
  const data = {
    handleToolInstalled,
    app: this.app
  }
  const [component, addToolButtonNode, modalNode] = Array.from(getDOMNodes(data))
  ok(component.isMounted())
  ok(TestUtils.isCompositeComponentWithType(component, AddApp))
})

test('configOptions', function() {
  const data = {
    handleToolInstalled,
    app: this.app
  }
  const [component, addToolButtonNode, modalNode] = Array.from(getDOMNodes(data))
  const options = component.configOptions()
  equal(options[0].props.name, 'name')
  equal(options[1].props.name, 'consumer_key')
  equal(options[2].props.name, 'shared_secret')
})

test('configSettings', function() {
  this.app.config_options = [{name: 'param1', param_type: 'text', default_value: 'val1'}]
  const data = {
    handleToolInstalled,
    app: this.app
  }
  const [component, addToolButtonNode, modalNode] = Array.from(getDOMNodes(data))
  const correctSettings = {
    param1: 'val1',
    name: 'Acclaim'
  }
  deepEqual(component.configSettings(), correctSettings)
})

test('mounting sets fields onto state', function() {
  const data = {
    handleToolInstalled,
    app: this.app
  }
  const component = renderComponent(data)
  deepEqual(component.state, {
    errorMessage: null,
    fields: {
      consumer_key: {description: 'Consumer Key', required: true, type: 'text', value: ''},
      name: {description: 'Name', required: true, type: 'text', value: 'Acclaim'},
      shared_secret: {description: 'Shared Secret', required: true, type: 'text', value: ''}
    },
    invalidFields: ['consumer_key', 'shared_secret'],
    isValid: false,
    modalIsOpen: false
  })
})
