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
            }
          },
          privacy_level: 'public'
        }
      ]
    },
    validScopes: [
      'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
      'https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly'
    ],
    validPlacements: ['file_menu']
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
    'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem'
  )
  expect(options).toContain(
    'https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly'
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
