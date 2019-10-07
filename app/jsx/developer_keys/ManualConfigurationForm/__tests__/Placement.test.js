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

import Placement from '../Placement'

const props = (overrides = {}, placementOverrides = {}) => {
  return {
    placementName: 'account_navigation',
    displayName: 'Account Navigation',
    placement: {
      target_link_uri: 'http://example.com',
      message_type: 'LtiResourceLinkRequest',
      icon_url: 'http://example.com/icon',
      text: 'asdf',
      selection_height: 10,
      selection_width: 10,
      ...placementOverrides
    },
    ...overrides
  }
}

it('generates the toolConfiguration', () => {
  const wrapper = mount(<Placement {...props()} />)
  const toolConfig = wrapper.instance().generateToolConfigurationPart()
  expect(Object.keys(toolConfig).length).toEqual(6)
  expect(toolConfig.icon_url).toEqual('http://example.com/icon')
})

const checkToolConfigPart = (toolConfig, path, value) => {
  expect(get(toolConfig, path)).toEqual(value)
}

const checkChange = (path, funcName, value, event = null) => {
  const wrapper = mount(<Placement {...props()} />)

  event = event || {target: {value}}
  event = Array.isArray(event) ? event : [event]

  wrapper.instance()[funcName](...event)
  checkToolConfigPart(wrapper.instance().generateToolConfigurationPart(), path, value)
}

it('changes the output when target_link_uri changes', () => {
  checkChange(['target_link_uri'], 'handleTargetLinkUriChange', 'http://new.example.com')
})

it('changes the output when icon_url changes', () => {
  checkChange(['icon_url'], 'handleIconUrlChange', 'http://example.com/new_icon')
})

it('changes the output when text changes', () => {
  checkChange(['text'], 'handleTextChange', 'New Text')
})

it('changes the output when selection_height changes', () => {
  checkChange(['selection_height'], 'handleSelectionHeightChange', 250)
})

it('changes the output when selection_width changes', () => {
  checkChange(['selection_width'], 'handleSelectionWidthChange', 250)
})

it('changes the output when message_type changes', () => {
  checkChange(['message_type'], 'handleMessageTypeChange', 'LtiDeepLinkingRequest', [
    null,
    'LtiDeepLinkingRequest'
  ])
})

it('cleans up invalid inputs', () => {
  const wrapper = mount(<Placement {...props({placementOverrides: {message_type: undefined}})} />)
  expect(wrapper.instance().valid()).toEqual(true)
})

it('is valid when valid', () => {
  const wrapper = mount(<Placement {...props()} />)
  expect(wrapper.instance().valid()).toEqual(true)
})

const placements = ['editor_button', 'migration_selection', 'homework_submission']

placements.forEach(placementName => {
  it('displays alert when placement only supports deep linking', () => {
    const wrapper = mount(<Placement {...props({placementName})} />)
    wrapper.find('button').simulate('click')
    expect(wrapper.exists('Alert')).toBeTruthy()
  })
})

const couldBeEither = ['assignment_selection', 'link_selection']

couldBeEither.forEach(placementName => {
  it('displays alert when placement supports deep linking and resource link and deep linking chosen', () => {
    const wrapper = mount(
      <Placement {...props({placementName}, {message_type: 'LtiDeepLinkingRequest'})} />
    )
    wrapper.find('button').simulate('click')
    expect(wrapper.exists('Alert')).toBeTruthy()
  })

  it('does not display alert when placement supports deep linking and resource link and deep linking chosen', () => {
    const wrapper = mount(<Placement {...props({placementName})} />)
    wrapper.find('ToggleDetails').simulate('click')
    expect(wrapper.exists('Alert')).toBeFalsy()
  })
})
