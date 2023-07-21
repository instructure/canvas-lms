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
import get from 'lodash/get'

import AdditionalSettings from '../AdditionalSettings'

const props = (overrides = {}, additionalSettingsOverrides = {}, settingsOverrides = {}) => {
  return {
    additionalSettings: {
      domain: 'www.example.com',
      tool_id: 'asdf',
      settings: {
        icon_url: 'http://example.com/icon',
        text: 'Text',
        selection_height: 10,
        selection_width: 10,
        ...settingsOverrides,
      },
      ...additionalSettingsOverrides,
    },
    custom_fields: {},
    ...overrides,
  }
}

it('generates the toolConfiguration', () => {
  const wrapper = mount(<AdditionalSettings {...props()} />)
  const toolConfig = wrapper.instance().generateToolConfigurationPart()
  expect(toolConfig.extensions.length).toEqual(1)
  const ext = toolConfig.extensions[0]
  expect(ext.domain).toEqual('www.example.com')
  expect(Object.keys(ext.settings).length).toEqual(4)
})

const checkToolConfigPart = (toolConfig, path, value) => {
  expect(get(toolConfig, path)).toEqual(value)
}

const checkChange = (path, funcName, in_value, out_value) => {
  out_value = out_value || in_value
  const wrapper = mount(<AdditionalSettings {...props()} />)

  wrapper.instance()[funcName]({target: {value: in_value}})
  checkToolConfigPart(wrapper.instance().generateToolConfigurationPart(), path, out_value)
}

it('changes the output when domain changes', () => {
  checkChange(['extensions', '0', 'domain'], 'handleDomainChange', 'new.example.com')
})

it('changes the output when tool_id changes', () => {
  checkChange(['extensions', '0', 'tool_id'], 'handleToolIdChange', 'qwerty')
})

it('changes the output when icon_url changes', () => {
  checkChange(
    ['extensions', '0', 'settings', 'icon_url'],
    'handleIconUrlChange',
    'http://example.com/new_icon'
  )
})

it('changes the output when text changes', () => {
  checkChange(['extensions', '0', 'settings', 'text'], 'handleTextChange', 'New Text')
})

it('changes the output when selection_height changes', () => {
  checkChange(
    ['extensions', '0', 'settings', 'selection_height'],
    'handleSelectionHeightChange',
    250
  )
})

it('changes the output when selection_width changes', () => {
  checkChange(['extensions', '0', 'settings', 'selection_width'], 'handleSelectionWidthChange', 250)
})

it('changes the output when custom_fields changes', () => {
  checkChange(['custom_fields'], 'handleCustomFieldsChange', 'foo=bar', {foo: 'bar'})
})
