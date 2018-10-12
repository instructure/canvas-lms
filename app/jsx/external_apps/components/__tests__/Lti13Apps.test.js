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
import Lti13Apps from '../Lti13Apps'

const defaultApps = () => [
  {
    app_id: 1,
    app_type: 'ContextExternalTool',
    description:
      'Talent provides an online, interactive video platform for professional development',
    enabled: true,
    installed_locally: true,
    name: 'Talent',
    context: 'Course',
    context_id: 1
  },
  {
    app_id: 2,
    app_type: 'Lti::ToolProxy',
    description: null,
    enabled: true,
    installed_locally: true,
    name: 'Twitter',
    context: 'Course',
    context_id: 1
  },
  {
    app_id: 3,
    app_type: 'Lti::ToolProxy',
    description: null,
    enabled: false,
    installed_locally: true,
    name: 'LinkedIn',
    context: 'Course',
    context_id: 1
  }
]

function newProps(overrides, contextType = 'Account') {
  return {
    store: {
      getState: () => ({
        lti13LoadStatus: 'success',
        lti13Tools: [],
        ...overrides
      }),
      filteredApps: defaultApps,
      installTool: jest.fn(),
      removeTool: jest.fn(),
      fetch13Tools: jest.fn()
    },
    contextType
  }
}

let wrapper = 'empty wrapper'

afterEach(() => {
  wrapper.unmount()
})

it('renders the appropriate number of rows', () => {
  const props = newProps()
  wrapper = mount(<Lti13Apps {...props} />)

  expect(wrapper.find('tr')).toHaveLength(4)
})

it('renders correct number of checkboxes', () => {
  const props = newProps()
  wrapper = mount(<Lti13Apps {...props} />)

  expect(wrapper.find({ type: 'checkbox' })).toHaveLength(3)
})

it('renders correct number of checked checkboxes', () => {
  const props = newProps()
  wrapper = mount(<Lti13Apps {...props} />)

  expect(wrapper.find('Checkbox').filterWhere(c => c.prop('checked'))).toHaveLength(2)
})

it('enables the checkbox when tool is installed in account', () => {
  const props = newProps({})
  wrapper = mount(<Lti13Apps {...props} />)
  expect(wrapper.instance().isDisabled({enabled: true, installed_in_current_course: false})).not.toBeTruthy()
})

it('enables the checkbox when context is course and tool is installed in course', () => {
  const props = newProps({}, 'course')
  wrapper = mount(<Lti13Apps {...props} />)
  expect(wrapper.instance().isDisabled({enabled: true, installed_in_current_course: true})).not.toBeTruthy()
})

it('disables the checkbox when context is course and tool is not in course', () => {
  const props = newProps({}, 'course')
  wrapper = mount(<Lti13Apps {...props} />)
  expect(wrapper.instance().isDisabled({enabled: true, installed_in_current_course: false})).toBeTruthy()
})

it('calls install tool on unchecked checkbox click', () => {
  const props = newProps()
  wrapper = mount(<Lti13Apps {...props} />)
  const uncheckedBox = wrapper.find({ type: 'checkbox' }).filterWhere(c => !c.prop('checked')).first()

  uncheckedBox.simulate('change')
  expect(props.store.installTool).toHaveBeenCalled()
})

it('calls remove tool on unchecked checkbox click', () => {
  const props = newProps()
  wrapper = mount(<Lti13Apps {...props} />)
  const uncheckedBox = wrapper.find({ type: 'checkbox' }).filterWhere(c => c.prop('checked')).first()

  uncheckedBox.simulate('change')
  expect(props.store.removeTool).toHaveBeenCalled()
})

it('calls fetch13Tools on mount if loading status is pending  ', () => {
  const props = newProps({lti13LoadStatus: 'pending'})
  wrapper = mount(<Lti13Apps {...props} />)

  expect(props.store.fetch13Tools).toHaveBeenCalled()
})
