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
import sinon from 'sinon'
import Scopes from '../Scopes'

function props(pending = false, requireScopes = true, onRequireScopesChange = () => {}) {
  return {
    developerKey: {
      allow_includes: true,
    },
    availableScopes: {
      oauth: [
        {
          resource: 'oauth',
          verb: 'GET',
          scope: '/auth/userinfo',
        },
      ],
      account_domain_lookups: [
        {
          resource: 'account_domain_lookups',
          verb: 'GET',
          path: '/api/v1/accounts/search',
          scope: 'url:GET|/api/v1/accounts/search',
        },
        {
          resource: 'account_domain_lookups',
          verb: 'POST',
          path: '/api/v1/account_domain_lookups',
          scope: 'url:POST|/api/v1/account_domain_lookups',
        },
      ],
    },
    availableScopesPending: pending,
    dispatch: () => {},
    listScopesSet: () => {},
    updateDeveloperKey: () => {},
    listDeveloperKeyScopesSet: () => {},
    requireScopes,
    onRequireScopesChange,
  }
}

describe('when the "includes" checkbox FF is set in the ENV', () => {
  let wrapper

  beforeEach(() => {
    window.ENV = {
      includesFeatureFlagEnabled: true,
    }

    wrapper = mount(<Scopes {...props()} />)
  })

  it('renders the "includes" checkbox', () => {
    expect(wrapper.exists("[data-automation='includes-checkbox']")).toEqual(true)
  })
})

it('renders a spinner if scope state is "pending"', () => {
  const wrapper = mount(<Scopes {...props(true)} />)
  const spinner = wrapper.find('#scopes-loading-spinner')
  expect(spinner.text()).toBe('Loading Available Scopes')
})

it('renders scopes if scope state is not "pending"', () => {
  const wrapper = mount(<Scopes {...props()} />)
  const spinner = wrapper.find('#scopes-loading-spinner')
  expect(spinner.exists()).toBe(false)
})

it('defaults the filter state to an empty string', () => {
  const wrapper = mount(<Scopes {...props()} />)
  expect(wrapper.state().filter).toBe('')
})

it('handles filter input change by setting the filter state', () => {
  const wrapper = mount(<Scopes {...props()} />)
  const eventDup = {currentTarget: {value: 'banana'}}
  wrapper.instance().handleFilterChange(eventDup)
  expect(wrapper.state().filter).toBe('banana')
})

it('renders Billboard if requireScopes is false', () => {
  const wrapper = mount(<Scopes {...props(undefined, false)} />)
  expect(wrapper.find('Billboard')).toHaveLength(2)
})

it('does not render search box if requireScopes is false', () => {
  const wrapper = mount(<Scopes {...props(undefined, false)} />)
  expect(wrapper.find('TextInput')).toHaveLength(0)
})

it('does not render Billboard if requireScopes is true', () => {
  const wrapper = mount(<Scopes {...props(undefined, true)} />)
  expect(wrapper.find('Billboard')).toHaveLength(0)
})

it('renders ScopesList if requireScopes is true', () => {
  const wrapper = mount(<Scopes {...props(undefined, true)} />)
  expect(wrapper.find('ScopesList')).toHaveLength(1)
})

it('does render search box if requireScopes is true', () => {
  const wrapper = mount(<Scopes {...props()} />)
  expect(wrapper.find('TextInput')).toHaveLength(3)
})

it('controls requireScopes change when clicking requireScopes button', () => {
  const requireScopesStub = sinon.stub()
  const wrapper = mount(<Scopes {...props(undefined, true, requireScopesStub)} />)
  wrapper
    .find('Checkbox')
    .filterWhere(n => n.prop('variant') === 'toggle')
    .at(1)
    .props()
    .onChange()
  expect(requireScopesStub.called).toBe(true)
})
