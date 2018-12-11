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
import CustomizationForm from '../CustomizationForm'

function newProps() {
  return {
    toolConfiguration: {
      title: 'Test Tool',
      scopes: [
        'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
        'https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly',
        'invalid-scope'
      ],
      extensions: [
        {
          tool_id: 'LTI 1.3 Test Tool',
          platform: 'canvas.instructure.com',
          settings: {
            file_menu: {
              url: 'https://lti-tool-provider-example.herokuapp.com/messages/blti',
              text: 'LTI 1.3 Test Tool (Course Nav)',
              message_type: 'LtiResourceLinkRequest'
            },
            invalid_placement: {
              url: 'https://lti-tool-provider-example.herokuapp.com/messages/blti',
              text: 'LTI 1.3 Test Tool (Course Nav)',
              message_type: 'LtiResourceLinkRequest'
            },
            no_message_type: {
              url: 'https://lti-tool-provider-example.herokuapp.com/messages/blti',
              text: 'LTI 1.3 Test Tool (Course Nav)'
            }
          },
          privacy_level: 'public'
        }
      ]
    },
    validScopes: {
      'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem': 'Line Item',
      'https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly': 'Result'
    },
    validPlacements: ['file_menu'],
    enabledScopes: [],
    disabledPlacements: [],
    dispatch: jest.fn(),
    setEnabledScopes: jest.fn(),
    setDisabledPlacements: jest.fn()
  }
}

function renderedOptions(table = 0) {
  return wrapper
    .find('Table')
    .at(table)
    .find('CustomizationOption')
    .map(opt => (
      opt.find('Checkbox').instance().props.name
    ))
}

let wrapper = 'empty wrapper'

afterEach(() => {
  wrapper.unmount()
})

it('renders an option for each valid scope', () => {
  wrapper = mount(<CustomizationForm {...newProps()} />)
  const options = renderedOptions()
  expect(options).toContain(
    'Line Item'
  )
  expect(options).toContain(
    'Result'
  )
})

it('does not render an option for invalid scopes', () => {
  wrapper = mount(<CustomizationForm {...newProps()} />)
  const options = renderedOptions()
  expect(options).not.toContain('invalid-scope')
})

it('renders an option for each valid placement', () => {
  wrapper = mount(<CustomizationForm {...newProps()} />)
  const options = renderedOptions(1)
  expect(options).toContain('file_menu')
})

it('does not render an option for invalid placements', () => {
  wrapper = mount(<CustomizationForm {...newProps()} />)
  const options = renderedOptions(1)
  expect(options).not.toContain('invalid_placement')
})

it('does not render tables if no options are provided', () => {
  const props = Object.assign(newProps(), {validScopes: [], validPlacements: []})
  wrapper = mount(<CustomizationForm {...props} />)
  expect(renderedOptions()).toHaveLength(0)
})

it('enables all valid scopes by default', () => {
  const props = newProps()
  wrapper = mount(<CustomizationForm {...props} />)
  expect(props.setEnabledScopes).toHaveBeenCalledWith([
    'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
    'https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly'
  ])
})

it('removes a scope from "selectedScopes" when it is toggled off', () => {
  const props = Object.assign(newProps(), {enabledScopes: ['https://purl.imsglobal.org/spec/lti-ags/scope/lineitem']})
  const event = {
    target: {
      value: 'Line Item'
    }
  }

  wrapper = mount(<CustomizationForm {...props} />)
  wrapper.instance().handleScopeChange(event)

  expect(props.setEnabledScopes).toHaveBeenCalledWith([])
})

it('adds a scope to "selectedScopes" when it is toggled on', () => {
  const props = newProps()
  const event = {
    target: {
      value: 'Line Item'
    }
  }

  wrapper = mount(<CustomizationForm {...props} />)
  wrapper.instance().handleScopeChange(event)

  expect(props.setEnabledScopes).toHaveBeenCalledWith([
    "https://purl.imsglobal.org/spec/lti-ags/scope/lineitem"
  ])
})

it('removes a placement from "disabledPlacements" when it is toggled off', () => {
  const props = Object.assign(newProps(), {disabledPlacements: ['account_navigation']})
  const event = {
    target: {
      value: 'account_navigation'
    }
  }

  wrapper = mount(<CustomizationForm {...props} />)
  wrapper.instance().handlePlacementChange(event)

  expect(props.setDisabledPlacements).toHaveBeenCalledWith([])
})

it('adds a placement from "disabledPlacements" when it is toggled on', () => {
  const props = newProps()
  const event = {
    target: {
      value: 'account_navigation'
    }
  }

  wrapper = mount(<CustomizationForm {...props} />)
  wrapper.instance().handlePlacementChange(event)

  expect(props.setDisabledPlacements).toHaveBeenCalledWith(['account_navigation'])
})

it('correctly retrieves the placement message type', () => {
  wrapper = mount(<CustomizationForm {...newProps()} />)
  expect(wrapper.instance().messageTypeFor('file_menu')).toEqual('LtiResourceLinkRequest')
})

it('returns null if the placement does not exist', () => {
  wrapper = mount(<CustomizationForm {...newProps()} />)
  expect(wrapper.instance().messageTypeFor('banana')).toBeFalsy()
})

it('returns null if the placement have a message type', () => {
  wrapper = mount(<CustomizationForm {...newProps()} />)
  expect(wrapper.instance().messageTypeFor('no_message_type')).toBeFalsy()
})