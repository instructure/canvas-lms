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

import ManualConfiguration from '../index'

const props = (overrides = {}) => {
  return {
    toolConfiguration: {},
    validScopes: {
      test: 'valid_scope',
    },
    validPlacements: ['aplacement'],
    ...overrides,
  }
}

it('renders form', () => {
  const wrapper = mount(<ManualConfiguration {...props()} />)
  expect(wrapper.find('RequiredValues').exists()).toBe(true)
})

it('generates the toolConfiguration', () => {
  const wrapper = mount(<ManualConfiguration {...props()} />)
  const toolConfig = wrapper.instance().generateToolConfiguration()
  expect(toolConfig.scopes).toBeDefined()
  expect(toolConfig.extensions.length).toEqual(1)
})
