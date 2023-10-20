/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {mount} from 'enzyme'
import ToolConfigurationForm from '../ToolConfigurationForm'

function newProps(overrides = {}) {
  return {
    toolConfiguration: {name: 'Test Tool', url: 'https://www.test.com/launch'},
    toolConfigurationUrl: 'https://www.test.com/config.json',
    validScopes: {},
    validPlacements: [],
    editing: false,
    showRequiredMessages: false,
    dispatch: jest.fn(),
    updateConfigurationMethod: jest.fn(),
    configurationMethod: 'json',
    updateToolConfiguration: Function.prototype,
    updateToolConfigurationUrl: Function.prototype,
    ...overrides,
  }
}

let wrapper = 'empty wrapper'

afterEach(() => {
  wrapper.unmount()
})

describe('when configuration method is by JSON', () => {
  beforeEach(() => {
    wrapper = mount(<ToolConfigurationForm {...newProps()} />)
    wrapper.setState({configurationType: 'json'})
  })

  it('renders the tool configuration JSON in a text area', () => {
    const textArea = wrapper.find('TextArea').at(0)
    expect(textArea.text()).toEqual(expect.stringContaining(newProps().toolConfiguration.url))
  })

  it('transitions to configuring by URL when the url option is selected', () => {
    const select = wrapper.find('SimpleSelect').at(1)
    select.instance().props.onChange({}, {value: 'url'})
    expect(wrapper.instance().props.updateConfigurationMethod).toHaveBeenCalled()
  })
})

describe('when configuration method is by URL', () => {
  beforeEach(() => {
    wrapper = mount(<ToolConfigurationForm {...newProps({configurationMethod: 'url'})} />)
  })

  it('renders the tool configuration URL in a text input', () => {
    const textInput = wrapper.find('TextInput').at(3)
    const expectedString = newProps().toolConfigurationUrl
    expect(textInput.html()).toEqual(expect.stringContaining(expectedString))
  })

  it('transitions to configuring by JSON when the json option is selected', () => {
    const select = wrapper.find('SimpleSelect').at(1)
    select.instance().props.onChange({}, {value: 'json'})
    expect(wrapper.instance().props.updateConfigurationMethod).toHaveBeenCalled()
  })
})

describe('when configuration method is manual', () => {
  beforeEach(() => {
    wrapper = mount(<ToolConfigurationForm {...newProps({configurationMethod: 'manual'})} />)
  })

  it('renders the manual configuration form', () => {
    expect(wrapper.find('ManualConfigurationForm').exists()).toEqual(true)
  })
})
