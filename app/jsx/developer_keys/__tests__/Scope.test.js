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
import { mount } from 'enzyme'
import DeveloperKeyScope from '../Scope'

const scope = {
  "resource":"account_domain_lookups",
  "verb":"GET",
  "path":"/api/v1/accounts/search",
  "scope":"url:GET|/api/v1/accounts/search"
}

it('checks the checkbox if the checked prop is true', () => {
  const props = {
    onChange: jest.fn(),
    checked: true,
    scope
  }

  const wrapper = mount(<DeveloperKeyScope {...props} />)
  expect(wrapper.find('input[type="checkbox"]').props().checked).toBe(true)
})


it('does not check the checkbox if the checked prop is false', () => {
  const props = {
    onChange: jest.fn(),
    checked: false,
    scope
  }

  const wrapper = mount(<DeveloperKeyScope {...props} />)
  expect(wrapper.find('input[type="checkbox"]').props().checked).toBe(false)
})

it('renders the scope scope', () => {
  const props = {
    onChange: jest.fn(),
    checked: false,
    scope
  }

  const wrapper = mount(<DeveloperKeyScope {...props} />)
  expect(wrapper.find('Checkbox').text()).toContain(scope.scope)
})

it('renders the scope verb', () => {
  const props = {
    onChange: jest.fn(),
    checked: false,
    scope
  }

  const wrapper = mount(<DeveloperKeyScope {...props} />)
  expect(wrapper.find('Checkbox').text()).toContain(scope.verb)
})
