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
import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import ToolConfigurationForm from '../ToolConfigurationForm'

function newProps(overrides = {}) {
  return {
    toolConfiguration: {
      name: 'Test Tool',
      url: 'https://www.test.com/launch',
      target_link_uri: 'https://example.com/target_link_uri',
    },
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
    prettifyPastedJson: jest.fn(),
    canPrettify: false,
    ...overrides,
  }
}

let wrapper = 'empty wrapper'

beforeEach(() => {
  wrapper = null
})

afterEach(() => {
  if (wrapper) {
    wrapper.unmount()
  }
})

describe('when configuration method is by JSON', () => {
  function mountForm(propOverrides = {}) {
    wrapper = mount(<ToolConfigurationForm {...newProps(propOverrides)} />)
    wrapper.setState({configurationType: 'json'})
  }

  it('renders the tool configuration JSON in a text area', () => {
    mountForm()
    const textArea = wrapper.find('TextArea').at(0)
    expect(textArea.text()).toEqual(expect.stringContaining(newProps().toolConfiguration.url))
  })

  it('transitions to configuring by URL when the url option is selected', () => {
    mountForm()
    const select = wrapper.find('SimpleSelect').at(1)
    select.instance().props.onChange({}, {value: 'url'})
    expect(wrapper.instance().props.updateConfigurationMethod).toHaveBeenCalled()
  })

  it('renders the text in the jsonString prop', () => {
    mountForm({jsonString: '{"test": "test"}'})
    const textArea = wrapper.find('TextArea').at(0)
    expect(textArea.text()).toEqual(expect.stringContaining('{"test": "test"}'))
  })

  it('prefers the text in the invalidJson prop even if it is an empty string', () => {
    mountForm({jsonString: '{"test": "test"}', invalidJson: ''})
    const textArea = wrapper.find('TextArea').at(0)
    expect(textArea.text()).not.toEqual(expect.stringContaining('test'))
  })

  it('renders a button that fires the prettifyPastedJson prop', () => {
    mountForm({canPrettify: true})
    const button = wrapper.find('Button').at(0)
    button.simulate('click')
    expect(wrapper.instance().props.prettifyPastedJson).toHaveBeenCalled()
  })

  it('does not render a visible manual configuration', async () => {
    const rendered = render(
      <ToolConfigurationForm {...newProps()} />
    )
    const elem1 = rendered.queryByText(/Target Link URI/)
    if (elem1) {
      expect(elem1).not.toBeVisible()
    }
    const elem2 = rendered.queryByText(/OpenID Connect Initiation Url/)
    if (elem2) {
      expect(elem2).not.toBeVisible()
    }
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

  it('renders a visible manual configuration', async () => {
    const rendered = render(
      <ToolConfigurationForm {...newProps({configurationMethod: 'manual'})} />
    )
    const elem1 = rendered.queryByText('* Target Link URI')
    expect(elem1).toBeVisible()
    const elem2 = rendered.queryByText('* OpenID Connect Initiation Url')
    expect(elem2).toBeVisible()
  })

  it('preserves state when changing to Pasted JSON mode and back again', async () => {
    const user = userEvent.setup()

    const props = newProps({configurationMethod: 'manual'})
    const rendered = render(<ToolConfigurationForm {...props} />)

    const oldUrl = props.toolConfiguration.target_link_uri
    const newUrl = oldUrl + 'abc'
    const input = rendered.queryByDisplayValue(oldUrl)
    await user.type(input, 'abc')

    expect(rendered.queryByDisplayValue(newUrl)).toBeTruthy()
    rendered.rerender(<ToolConfigurationForm {...newProps({configurationMethod: 'json'})} />)
    rendered.rerender(<ToolConfigurationForm {...newProps({configurationMethod: 'manual'})} />)
    expect(rendered.queryByDisplayValue(newUrl)).toBeTruthy()
  })
})
