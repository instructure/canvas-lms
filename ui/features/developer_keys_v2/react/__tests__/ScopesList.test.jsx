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
import DeveloperKeyScopesList from '../ScopesList'

const scopes = {
  oauth: [
    {
      resource: 'oauth',
      verb: 'GET',
      scope: '/auth/userinfo',
    },
  ],
  oauth1: [
    {
      resource: 'oauth',
      verb: 'GET',
      scope: '/auth/userinfo',
    },
  ],
  oaut2: [
    {
      resource: 'oauth',
      verb: 'GET',
      scope: '/auth/userinfo',
    },
  ],
  oauth3: [
    {
      resource: 'oauth',
      verb: 'GET',
      scope: '/auth/userinfo',
    },
  ],
  oauth4: [
    {
      resource: 'oauth',
      verb: 'GET',
      scope: '/auth/userinfo',
    },
  ],
  oauth5: [
    {
      resource: 'oauth',
      verb: 'GET',
      scope: '/auth/userinfo',
    },
  ],
  oauth6: [
    {
      resource: 'oauth',
      verb: 'GET',
      scope: '/auth/userinfo',
    },
  ],
  oauth7: [
    {
      resource: 'oauth',
      verb: 'GET',
      scope: '/auth/userinfo',
    },
  ],
  oauth8: [
    {
      resource: 'oauth',
      verb: 'GET',
      scope: '/auth/userinfo',
    },
  ],
  oauth9: [
    {
      resource: 'oauth',
      verb: 'GET',
      scope: '/auth/userinfo',
    },
  ],
  oauth10: [
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
}

const props = {
  dispatch: () => {},
  listDeveloperKeyScopesSet: () => {},
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
  filter: '',
  actions: {listDeveloperKeyScopesSet: () => {}},
}

it('renders each group', () => {
  const wrapper = mount(<DeveloperKeyScopesList {...props} />)
  expect(wrapper.find('.LazyLoad')).toHaveLength(2)
})

it('uses the correct handler the checkbox is checked', () => {
  const wrapper = mount(<DeveloperKeyScopesList {...props} />)
  const stubbedHandler = jest.fn()
  const component = wrapper.instance()
  const checkBox = wrapper.find("input[type='checkbox']")

  component.handleReadOnlySelected = stubbedHandler
  component.forceUpdate()
  wrapper.update()

  checkBox.simulate('change', {target: {checked: true}})
  expect(stubbedHandler).toHaveBeenCalled()
})

it('only renders groups with names that match the fitler', () => {
  const filterProps = {...props, filter: 'Account'}
  const wrapper = mount(<DeveloperKeyScopesList {...filterProps} />)
  expect(wrapper.find('.LazyLoad')).toHaveLength(1)
})

it('only renders 8 groups on the initaial render', () => {
  const manyScopesProps = {...props, availableScopes: scopes}
  const wrapper = mount(<DeveloperKeyScopesList {...manyScopesProps} />)
  expect(wrapper.instance().state.availableScopes).toHaveLength(8)
})

describe('handleReadOnlySelected', () => {
  it('selects all scopes with GET as the verb', () => {
    const wrapper = mount(<DeveloperKeyScopesList {...props} />)
    const fakeEvent = {
      currentTarget: {
        checked: true,
      },
    }

    wrapper.instance().handleReadOnlySelected(fakeEvent)
    const state = wrapper.instance().state
    expect(state.selectedScopes).toEqual(
      expect.arrayContaining(['/auth/userinfo', 'url:GET|/api/v1/accounts/search'])
    )
  })

  it('deselects all scopes with GET as the verb', () => {
    const wrapper = mount(<DeveloperKeyScopesList {...props} />)
    const fakeSelectEvent = {
      currentTarget: {
        checked: true,
      },
    }
    const fakeDeselectEvent = {
      currentTarget: {
        checked: false,
      },
    }

    wrapper.instance().handleReadOnlySelected(fakeSelectEvent)
    wrapper.instance().handleReadOnlySelected(fakeDeselectEvent)

    const state = wrapper.instance().state
    expect(state.selectedScopes).toEqual(expect.arrayContaining([]))
  })
})

describe('initial state', () => {
  it('initializes selectedScopes to empty array if selectedScopes prop is undefined', () => {
    const wrapper = mount(<DeveloperKeyScopesList {...props} />)
    const state = wrapper.instance().state
    expect(state.selectedScopes).toEqual([])
  })
})

describe('verify no duplicate elements get posted', () => {
  it('filter out duplicate elements when setting the state', () => {
    const wrapper = mount(<DeveloperKeyScopesList {...props} />)
    const duplicate = ['a', 'b', 'c', 'd', 'a', 'a', 'a', 'b']
    wrapper.instance().setSelectedScopes(duplicate)
    const state = wrapper.instance().state
    expect(state.selectedScopes).toEqual(expect.arrayContaining(['a', 'b', 'c', 'd']))
  })

  it('does nothing to empty array when setting the state', () => {
    const wrapper = mount(<DeveloperKeyScopesList {...props} />)
    wrapper.instance().setSelectedScopes([])
    const state = wrapper.instance().state
    expect(state.selectedScopes).toEqual([])
  })

  it('does nothing to array with no duplicate elements when setting the state', () => {
    const wrapper = mount(<DeveloperKeyScopesList {...props} />)
    const noDuplicate = ['a', 'b', 'c', 'd', 'e', 'f', 'g']
    wrapper.instance().setSelectedScopes(noDuplicate)
    const state = wrapper.instance().state
    expect(state.selectedScopes).toEqual(
      expect.arrayContaining(['a', 'b', 'c', 'd', 'e', 'f', 'g'])
    )
  })
})

describe('setSelectedScopes', () => {
  describe('Read Only check box', () => {
    it('is not checked when no scope is selected', () => {
      const wrapper = mount(<DeveloperKeyScopesList {...props} />)
      wrapper.instance().setSelectedScopes([])
      const state = wrapper.instance().state
      expect(state.readOnlySelected).toEqual(false)
    })

    it('is checked when all possible GET is selected', () => {
      const wrapper = mount(<DeveloperKeyScopesList {...props} />)
      wrapper.instance().setSelectedScopes(['/auth/userinfo', 'url:GET|/api/v1/accounts/search'])
      const state = wrapper.instance().state
      expect(state.readOnlySelected).toEqual(true)
    })

    it('is not checked when some of the GET is selected but nothing else', () => {
      const wrapper = mount(<DeveloperKeyScopesList {...props} />)
      wrapper.instance().setSelectedScopes(['/auth/userinfo'])
      const state = wrapper.instance().state
      expect(state.readOnlySelected).toEqual(false)
    })

    it('is not checked when any verb that is not GET and all possible GET is selected', () => {
      const wrapper = mount(<DeveloperKeyScopesList {...props} />)
      wrapper
        .instance()
        .setSelectedScopes([
          'url:POST|/api/v1/account_domain_lookups',
          '/auth/userinfo',
          'url:GET|/api/v1/accounts/search',
        ])
      const state = wrapper.instance().state
      expect(state.readOnlySelected).toEqual(false)
    })

    it('is not checked when any verb that is not GET is selected only', () => {
      const wrapper = mount(<DeveloperKeyScopesList {...props} />)
      wrapper.instance().setSelectedScopes(['url:POST|/api/v1/account_domain_lookups'])
      const state = wrapper.instance().state
      expect(state.readOnlySelected).toEqual(false)
    })
  })
})
