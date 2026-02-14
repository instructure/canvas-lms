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

import * as Actions from '../actions'
import {fakeAxios} from '../components/__tests__/utils'

describe('getCspSettings', () => {
  const fakeTools = {
    'instructure.com': [
      {
        id: '1',
        name: 'Cool Tool 1',
        account_id: '1',
      },
    ],
    'bridgelms.com': [
      {
        id: '2',
        name: 'Cool Tool 2',
        account_id: '1',
      },
    ],
  }
  const fakeEffectiveList = ['effective.example']
  const fakeAccountList = ['account.example']

  it('dispatches a SET_CSP_SETTINGS action with the settings on success', async () => {
    const thunk = Actions.getCspSettings('account', 3, true)
    const fakeDispatch = vi.fn()
    const overrideAxios = {
      ...fakeAxios,
      get: vi.fn(() =>
        Promise.resolve({
          data: {
            enabled: true,
            inherited: false,
            effective_whitelist: fakeEffectiveList,
            current_account_whitelist: fakeAccountList,
            tools_whitelist: fakeTools,
          },
        }),
      ),
    }
    await thunk(fakeDispatch, null, {axios: overrideAxios})
    expect(fakeDispatch).toHaveBeenCalledWith({
      payload: {
        enabled: true,
        inherited: false,
        domains: {
          effective: fakeEffectiveList,
          account: fakeAccountList,
          tools: fakeTools,
        },
        isSubAccount: true,
      },
      type: 'SET_CSP_SETTINGS',
    })
  })

  it('dispatches a SET_ERROR action on failure', async () => {
    const thunk = Actions.getCspSettings('account', 3, true)
    const fakeDispatch = vi.fn()
    const overrideAxios = {
      ...fakeAxios,
      get: vi.fn(() => Promise.reject(new Error('Network error'))),
    }
    await thunk(fakeDispatch, null, {axios: overrideAxios})
    expect(fakeDispatch).toHaveBeenCalledWith({
      payload: 'GET_CSP_SETTINGS',
      type: 'SET_ERROR',
    })
  })
})

describe('setCspEnabledAction', () => {
  it('creates a SET_CSP_ENABLED action when passed a boolean value', () => {
    const action = Actions.setCspEnabledAction(true)
    expect(action.type).toBe('SET_CSP_ENABLED')
    expect(action.payload).toBe(true)
    expect(action.error).toBeUndefined()
  })
  it('creates an error action if passed a non-boolean value', () => {
    const action = Actions.setCspEnabledAction('yes')
    expect(action.type).toBe('SET_CSP_ENABLED')
    expect(action.error).toBe(true)
    expect(action.payload).toBeInstanceOf(Error)
    expect(action.payload.message).toBe('Can only set to Boolean values')
  })
  it('creates a SET_CSP_ENABLED_OPTIMISTIC action when optimistic option is given', () => {
    const action = Actions.setCspEnabledAction(true, {optimistic: true})
    expect(action.type).toBe('SET_CSP_ENABLED_OPTIMISTIC')
    expect(action.payload).toBe(true)
    expect(action.error).toBeUndefined()
  })
})

describe('setCspEnabled', () => {
  it('converts non-plural contexts to plural', () => {
    const thunk = Actions.setCspEnabled('course', 1, true)
    const fakeDispatch = vi.fn()

    thunk(fakeDispatch, null, {axios: fakeAxios})
    expect(fakeAxios.put).toHaveBeenCalledWith(expect.stringContaining('courses'), {
      status: 'enabled',
    })
  })

  it('does not modify plural contexts', () => {
    const thunk = Actions.setCspEnabled('courses', 1, true)
    const fakeDispatch = vi.fn()
    thunk(fakeDispatch, null, {axios: fakeAxios})
    expect(fakeAxios.put).toHaveBeenCalledWith(expect.stringContaining('courses'), {
      status: 'enabled',
    })
  })

  it('dispatches an optimistic action followed by the final result', async () => {
    const thunk = Actions.setCspEnabled('courses', 1, true)
    const fakeDispatch = vi.fn()
    const overrideAxios = {
      ...fakeAxios,
      put: vi.fn(() => Promise.resolve({data: {enabled: true}})),
    }
    await thunk(fakeDispatch, null, {axios: overrideAxios})
    expect(fakeDispatch).toHaveBeenNthCalledWith(1, {
      payload: true,
      type: 'SET_CSP_ENABLED_OPTIMISTIC',
    })
    expect(fakeDispatch).toHaveBeenNthCalledWith(2, {
      payload: true,
      type: 'SET_CSP_ENABLED',
    })
  })

  it('dispatches a SET_ERROR action on failure', async () => {
    const thunk = Actions.setCspEnabled('courses', 1, true)
    const fakeDispatch = vi.fn()
    const overrideAxios = {
      ...fakeAxios,
      put: vi.fn(() => Promise.reject(new Error('Network error'))),
    }
    await thunk(fakeDispatch, null, {axios: overrideAxios})
    expect(fakeDispatch).toHaveBeenCalledWith({
      payload: 'SET_CSP_ENABLED',
      type: 'SET_ERROR',
    })
  })
})

describe('addDomainAction', () => {
  it('creates an ADD_DOMAIN action when passed string value', () => {
    const action = Actions.addDomainAction('instructure.com', 'account')
    expect(action.type).toBe('ADD_DOMAIN')
    expect(action.payload).toEqual({account: 'instructure.com'})
    expect(action.error).toBeUndefined()
  })
  it('creates an error action if passed a non-string value', () => {
    const action = Actions.addDomainAction(true, 'account')
    expect(action.type).toBe('ADD_DOMAIN')
    expect(action.error).toBe(true)
    expect(action.payload).toBeInstanceOf(Error)
    expect(action.payload.message).toBe('Can only set to String values')
  })
  it('creates an error action if given an invalid domainType', () => {
    const action = Actions.addDomainAction('instructure', 'subaccount')
    expect(action.type).toBe('ADD_DOMAIN')
    expect(action.error).toBe(true)
    expect(action.payload).toBeInstanceOf(Error)
    expect(action.payload.message).toBe('domainType is invalid')
  })

  it('creates an ADD_DOMAIN_OPTIMISTIC action when optimistic option is given', () => {
    const action = Actions.addDomainAction('instructure.com', 'account', {optimistic: true})
    expect(action.type).toBe('ADD_DOMAIN_OPTIMISTIC')
    expect(action.payload).toEqual({account: 'instructure.com'})
    expect(action.error).toBeUndefined()
  })
})

describe('addDomain', () => {
  it('dispatches an optimistic action followed by the final result', async () => {
    const thunk = Actions.addDomain('account', 1, 'instructure.com')
    const fakeDispatch = vi.fn()
    await thunk(fakeDispatch, null, {axios: fakeAxios})
    expect(fakeDispatch).toHaveBeenNthCalledWith(1, {
      payload: {account: 'instructure.com'},
      type: 'ADD_DOMAIN_OPTIMISTIC',
    })
    expect(fakeDispatch).toHaveBeenNthCalledWith(2, {
      payload: {account: 'instructure.com'},
      type: 'ADD_DOMAIN',
    })
  })

  it('calls the afterAdd function after dispatching', async () => {
    const fakeAfterAdd = vi.fn()
    const thunk = Actions.addDomain('account', 1, 'instructure.com', fakeAfterAdd)
    const fakeDispatch = vi.fn()
    await thunk(fakeDispatch, null, {axios: fakeAxios})
    expect(fakeAfterAdd).toHaveBeenCalled()
  })

  it('dispatches a SET_ERROR action on failure', async () => {
    const thunk = Actions.addDomain('account', 1, 'instructure.com')
    const fakeDispatch = vi.fn()
    const overrideAxios = {
      ...fakeAxios,
      post: vi.fn(() => Promise.reject(new Error('Network error'))),
    }
    await thunk(fakeDispatch, null, {axios: overrideAxios})
    expect(fakeDispatch).toHaveBeenCalledWith({
      payload: 'ADD_DOMAIN',
      type: 'SET_ERROR',
    })
  })
})

describe('addDomainBulkAction', () => {
  it('creates a ADD_DOMAIN_BULK action when passed an value', () => {
    const domainMap = {
      account: ['instructure.com'],
      tools: {
        'google.com': [
          {
            id: '1',
            name: 'Cool Tool 1',
            account_id: '1',
          },
        ],
      },
    }
    const action = Actions.addDomainBulkAction(domainMap)
    expect(action.type).toBe('ADD_DOMAIN_BULK')
    expect(action.payload).toEqual({
      account: ['instructure.com'],
      tools: {
        'google.com': [
          {
            id: '1',
            name: 'Cool Tool 1',
            account_id: '1',
          },
        ],
      },
    })
    expect(action.error).toBeUndefined()
  })
  it('creates an error action if passed an invalid domainMap', () => {
    const action = Actions.addDomainBulkAction({
      lti: ['google.com'],
    })
    expect(action.type).toBe('ADD_DOMAIN_BULK')
    expect(action.error).toBe(true)
    expect(action.payload).toBeInstanceOf(Error)
    expect(action.payload.message).toBe('Invalid domain type key provided in domainsMap')
  })
})

describe('removeDomainAction', () => {
  it('creates an REMOVE_DOMAIN action when passed a string value', () => {
    const action = Actions.removeDomainAction('instructure.com')
    expect(action.type).toBe('REMOVE_DOMAIN')
    expect(action.payload).toBe('instructure.com')
    expect(action.error).toBeUndefined()
  })
  it('creates an error action if passed a non-string value', () => {
    const action = Actions.removeDomainAction(false)
    expect(action.type).toBe('REMOVE_DOMAIN')
    expect(action.error).toBe(true)
    expect(action.payload).toBeInstanceOf(Error)
    expect(action.payload.message).toBe('Domain can only set to String values')
  })
  it('creates a REMOVE_DOMAIN_OPTIMISTIC action when optimistic option is given', () => {
    const action = Actions.setCspEnabledAction('instructure.com', {optimistic: true})
    expect(action.type).toBe('SET_CSP_ENABLED_OPTIMISTIC')
    expect(action.error).toBe(true)
    expect(action.payload).toBeInstanceOf(Error)
    expect(action.payload.message).toBe('Can only set to Boolean values')
  })
})

describe('removeDomain', () => {
  it('dispatches an optimistic action followed by the final result', async () => {
    const thunk = Actions.removeDomain('account', 1, 'instructure.com')
    const fakeDispatch = vi.fn()
    await thunk(fakeDispatch, null, {axios: fakeAxios})
    expect(fakeDispatch).toHaveBeenNthCalledWith(1, {
      payload: 'instructure.com',
      type: 'REMOVE_DOMAIN_OPTIMISTIC',
    })
    expect(fakeDispatch).toHaveBeenNthCalledWith(2, {
      payload: 'instructure.com',
      type: 'REMOVE_DOMAIN',
    })
  })

  it('dispatches a SET_ERROR action on failure', async () => {
    const thunk = Actions.removeDomain('account', 1, 'instructure.com')
    const fakeDispatch = vi.fn()
    const overrideAxios = {
      ...fakeAxios,
      delete: vi.fn(() => Promise.reject(new Error('Network error'))),
    }
    await thunk(fakeDispatch, null, {axios: overrideAxios})
    expect(fakeDispatch).toHaveBeenCalledWith({
      payload: 'REMOVE_DOMAIN',
      type: 'SET_ERROR',
    })
  })
})

describe('setCspInheritedAction', () => {
  it('creates an SET_CSP_INHERITED action when passed a boolean value', () => {
    const action = Actions.setCspInheritedAction(true)
    expect(action.type).toBe('SET_CSP_INHERITED')
    expect(action.payload).toBe(true)
    expect(action.error).toBeUndefined()
  })
  it('creates an error action if passed a non-boolean value', () => {
    const action = Actions.setCspInheritedAction('string')
    expect(action.type).toBe('SET_CSP_INHERITED')
    expect(action.error).toBe(true)
    expect(action.payload).toBeInstanceOf(Error)
    expect(action.payload.message).toBe('Can only set to Boolean values')
  })
  it('creates a SET_CSP_INHERITED_OPTIMISTIC action when optimistic option is given', () => {
    const action = Actions.setCspInheritedAction(true, {optimistic: true})
    expect(action.type).toBe('SET_CSP_INHERITED_OPTIMISTIC')
    expect(action.payload).toBe(true)
    expect(action.error).toBeUndefined()
  })
})

describe('setCspInherited', () => {
  it('dispatches a optimistic value followed by the actual result', async () => {
    const thunk = Actions.setCspInherited('account', 1, true)
    const fakeDispatch = vi.fn()
    const fakeGetState = () => ({})
    const overrideAxios = {
      ...fakeAxios,
      put: vi.fn(() =>
        Promise.resolve({
          data: {inherited: true, enabled: false},
        }),
      ),
    }
    await thunk(fakeDispatch, fakeGetState, {axios: overrideAxios})
    expect(fakeDispatch).toHaveBeenNthCalledWith(1, {
      payload: true,
      type: 'SET_CSP_INHERITED_OPTIMISTIC',
    })
    expect(fakeDispatch).toHaveBeenNthCalledWith(2, {
      payload: true,
      type: 'SET_CSP_INHERITED',
    })
  })

  it('updates the enabled status and domain list when successful', async () => {
    const thunk = Actions.setCspInherited('account', 1, false)
    const fakeDispatch = vi.fn()
    const fakeGetState = () => ({})
    const overrideAxios = {
      ...fakeAxios,
      put: vi.fn(() =>
        Promise.resolve({
          data: {inherited: true, enabled: true},
        }),
      ),
    }
    await thunk(fakeDispatch, fakeGetState, {axios: overrideAxios})
    expect(fakeDispatch).toHaveBeenCalledWith({
      payload: true,
      type: 'SET_CSP_ENABLED',
    })
    expect(fakeDispatch).toHaveBeenCalledWith({
      payload: {effective: [], account: [], tools: {}},
      type: 'ADD_DOMAIN_BULK',
    })
  })

  it('sets the dirty status when cspInherited is true but then switches to false with no account whitelist', async () => {
    const thunk = Actions.setCspInherited('account', 1, false)
    const fakeDispatch = vi.fn()
    const fakeGetState = () => ({cspInherited: true})
    const overrideAxios = {
      ...fakeAxios,
      put: vi.fn(() =>
        Promise.resolve({
          data: {inherited: false, enabled: true, current_account_whitelist: []},
        }),
      ),
    }
    await thunk(fakeDispatch, fakeGetState, {axios: overrideAxios})
    expect(fakeDispatch).toHaveBeenCalledWith({
      payload: true,
      type: 'SET_DIRTY',
    })
  })

  it('dispatches a SET_ERROR action on failure', async () => {
    const thunk = Actions.setCspInherited('account', 1, false)
    const fakeDispatch = vi.fn()
    const fakeGetState = () => ({cspInherited: true})
    const overrideAxios = {
      ...fakeAxios,
      put: vi.fn(() => Promise.reject(new Error('Network error'))),
    }
    await thunk(fakeDispatch, fakeGetState, {axios: overrideAxios})
    expect(fakeDispatch).toHaveBeenCalledWith({
      payload: 'SET_CSP_INHERITED',
      type: 'SET_ERROR',
    })
  })
})

describe('setDirtyAction', () => {
  it('creates a SET_DIRTY action when passed a boolean value', () => {
    const action = Actions.setDirtyAction(true)
    expect(action.type).toBe('SET_DIRTY')
    expect(action.payload).toBe(true)
    expect(action.error).toBeUndefined()
  })
  it('creates an error action if passed a non-boolean value', () => {
    const action = Actions.setDirtyAction('yes')
    expect(action.type).toBe('SET_DIRTY')
    expect(action.error).toBe(true)
    expect(action.payload).toBeInstanceOf(Error)
    expect(action.payload.message).toBe('Can only set to Boolean values')
  })
})

describe('copyInheritedAction', () => {
  it('creates COPY_INHERITED action', () => {
    const action = Actions.copyInheritedAction([])
    expect(action.type).toBe('COPY_INHERITED')
    expect(action.payload).toEqual([])
    expect(action.error).toBeUndefined()
  })
})

describe('copyInheritedIfNeeded', () => {
  it('does does nothing if isDirty state is false', async () => {
    const thunk = Actions.copyInheritedIfNeeded('account', 1)
    const fakeDispatch = vi.fn()
    const fakeGetState = () => ({
      isDirty: false,
      whitelistedDomains: {inherited: ['canvaslms.com']},
    })
    await thunk(fakeDispatch, fakeGetState, {axios: fakeAxios})
    expect(fakeDispatch).not.toHaveBeenCalled()
  })

  it('dispatches a setDirtyAction and a copyInherited action when the request completes', async () => {
    const thunk = Actions.copyInheritedIfNeeded('account', 1)
    const fakeDispatch = vi.fn()
    const fakeGetState = () => ({isDirty: true, whitelistedDomains: {inherited: ['canvaslms.com']}})
    const overrideAxios = {
      ...fakeAxios,
      post: vi.fn(() =>
        Promise.resolve({
          data: {inherited: false, enabled: true, current_account_whitelist: ['canvaslms.com']},
        }),
      ),
    }
    await thunk(fakeDispatch, fakeGetState, {axios: overrideAxios})
    expect(fakeDispatch).toHaveBeenCalledWith({
      payload: false,
      type: 'SET_DIRTY',
    })
    expect(fakeDispatch).toHaveBeenCalledWith({
      payload: ['canvaslms.com'],
      type: 'COPY_INHERITED',
    })
  })

  it('adds the modifiedDomainOption.add domain to the list of domains to be copied', async () => {
    const thunk = Actions.copyInheritedIfNeeded('account', 1, {add: 'instructure.com'})
    const fakeDispatch = vi.fn()
    const fakeGetState = () => ({isDirty: true, whitelistedDomains: {inherited: ['canvaslms.com']}})
    await thunk(fakeDispatch, fakeGetState, {axios: fakeAxios})
    expect(fakeAxios.post).toHaveBeenCalledWith(
      '/api/v1/accounts/1/csp_settings/domains/batch_create',
      {domains: ['canvaslms.com', 'instructure.com']},
    )
  })

  it('removes the modifiedDomainOption.delete domain from the list of domains to be copied', async () => {
    const thunk = Actions.copyInheritedIfNeeded('account', 1, {delete: 'instructure.com'})
    const fakeDispatch = vi.fn()
    const fakeGetState = () => ({
      isDirty: true,
      whitelistedDomains: {inherited: ['canvaslms.com', 'instructure.com']},
    })
    await thunk(fakeDispatch, fakeGetState, {axios: fakeAxios})
    expect(fakeAxios.post).toHaveBeenCalledWith(
      '/api/v1/accounts/1/csp_settings/domains/batch_create',
      {domains: ['canvaslms.com']},
    )
  })

  it('dispatches a SET_ERROR action on failure', async () => {
    const thunk = Actions.copyInheritedIfNeeded('account', 1)
    const fakeDispatch = vi.fn()
    const fakeGetState = () => ({isDirty: true, whitelistedDomains: {inherited: ['canvaslms.com']}})
    const overrideAxios = {
      ...fakeAxios,
      post: vi.fn(() => Promise.reject(new Error('Network error'))),
    }
    await thunk(fakeDispatch, fakeGetState, {axios: overrideAxios})
    expect(fakeDispatch).toHaveBeenCalledWith({
      payload: 'COPY_INHERITED',
      type: 'SET_ERROR',
    })
  })
})
