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
import DeveloperKeyScopesGroup from '../ScopesGroup'

const scopes = [{
    "resource":"account_domain_lookups",
    "verb":"GET",
    "path":"/api/v1/accounts/search",
    "scope":"url:GET|/api/v1/accounts/search"
  },
  {
    "resource":"account_domain_lookups",
    "verb":"POST",
    "path":"/api/v1/accounts/search",
    "scope":"url:POST|/api/v1/accounts/search"
  }]

const props = {
  setSelectedScopes: jest.fn(),
  setReadOnlySelected: jest.fn(),
  selectedScopes: [scopes[0].scope],
  scopes,
  name: 'Cool Scope Group'
}

it("adds all scopes to 'selected scopes' when the checkbox is checked", () => {
  const wrapper = mount(<DeveloperKeyScopesGroup {...props} />)
  const checkBox = wrapper.find('input[type="checkbox"]')
  checkBox.simulate('change', { target: { checked: true } })
  expect(props.setSelectedScopes).toBeCalled()
})

it("removes all scopes from 'selected scopes' when the checbox is unchecked", () => {
  const wrapper = mount(<DeveloperKeyScopesGroup {...props} />)
  const checkBox = wrapper.find('input[type="checkbox"]')
  checkBox.simulate('change', { target: { checked: true } })
  checkBox.simulate('change', { target: { checked: false } })
  expect(props.setSelectedScopes).toHaveBeenCalledTimes(3)
})

it("checks the selected scopes", () => {
  const wrapper = mount(<DeveloperKeyScopesGroup {...props} />)
  wrapper.find('button').first().simulate('click')
  const checkBox = wrapper.find('input[value="url:GET|/api/v1/accounts/search"]').first()
  expect(checkBox.props().checked).toBe(true)
})

it("renders the http verb for each selected scope", () => {
  const wrapper = mount(<DeveloperKeyScopesGroup {...props} />)
  const button = wrapper.find('button').first()
  expect(button.text()).toContain('GET')
})

it("does not render the http verb for non-selected scopes", () => {
  const wrapper = mount(<DeveloperKeyScopesGroup {...props} />)
  const button = wrapper.find('button').first()
  expect(button.text()).not.toContain('POST')
})

it("renders the scope group name", () => {
  const wrapper = mount(<DeveloperKeyScopesGroup {...props} />)
  const button = wrapper.find('button').first()
  expect(button.text()).toContain(props.name)
})
