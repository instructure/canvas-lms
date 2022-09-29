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

import Placements from '../Placements'

const props = (overrides = {}, placementOverrides = {}) => {
  return {
    validPlacements: ['account_navigation', 'course_navigation'],
    placements: [
      {
        placement: 'account_navigation',
        target_link_uri: 'http://example.com',
        message_type: 'LtiResourceLinkRequest',
        icon_url: 'http://example.com/icon',
        text: 'asdf',
        selection_height: 10,
        selection_width: 10,
        ...placementOverrides,
      },
    ],
    ...overrides,
  }
}

it('allows empty placements', () => {
  const propsNoPlacements = {...props(), placements: []}
  const wrapper = mount(<Placements {...propsNoPlacements} />)
  expect(wrapper.instance().valid()).toEqual(true)
})

it('generates the toolConfiguration', () => {
  const wrapper = mount(<Placements {...props()} />)
  const toolConfig = wrapper.instance().generateToolConfigurationPart()
  expect(toolConfig.length).toEqual(1)
  expect(toolConfig[0].icon_url).toEqual('http://example.com/icon')
})

it('generates the displayNames correctly', () => {
  const wrapper = mount(<Placements {...props()} />)
  expect(wrapper.text()).toContain('Account Navigation')
  expect(wrapper.text()).not.toContain('Course Navigation')
})

it('adds placements', () => {
  const wrapper = mount(<Placements {...props()} />)
  wrapper.instance().handlePlacementSelect(['account_navigation', 'course_navigation'])
  expect(wrapper.text()).toContain('Account Navigation')
  expect(wrapper.text()).toContain('Course Navigation')
})

it('adds new placements to output', () => {
  const wrapper = mount(<Placements {...props()} />)
  wrapper.instance().handlePlacementSelect(['account_navigation', 'course_navigation'])
  const toolConfig = wrapper.instance().generateToolConfigurationPart()
  expect(toolConfig.length).toEqual(2)
  expect(toolConfig[1].placement).toEqual('course_navigation')
})
