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

describe('setCspEnabledAction', () => {
  it('creates a SET_CSP_ENABLED action when passed a boolean value', () => {
    expect(Actions.setCspEnabledAction(true)).toMatchSnapshot()
  })
  it('creates an error action if passed a non-boolean value', () => {
    expect(Actions.setCspEnabledAction('yes')).toMatchSnapshot()
  })
  it('creates a SET_CSP_ENABLED_OPTIMISTIC action when optimistic option is given', () => {
    expect(Actions.setCspEnabledAction(true, {optimistic: true})).toMatchSnapshot()
  })
})

describe('setCspEnabled', () => {
  it('converts non-plural contexts to plural', () => {
    const thunk = Actions.setCspEnabled('course', 1, true)
    const fakeDispatch = jest.fn()
    const fakeAxios = {
      put: jest.fn(() => ({then() {}})),
    }
    thunk(fakeDispatch, null, {axios: fakeAxios})
    expect(fakeAxios.put).toHaveBeenCalledWith(expect.stringContaining('courses'), {
      status: 'enabled',
    })
  })

  it('does not modify plural contexts', () => {
    const thunk = Actions.setCspEnabled('courses', 1, true)
    const fakeDispatch = jest.fn()
    const fakeAxios = {
      put: jest.fn(() => ({then() {}})),
    }
    thunk(fakeDispatch, null, {axios: fakeAxios})
    expect(fakeAxios.put).toHaveBeenCalledWith(expect.stringContaining('courses'), {
      status: 'enabled',
    })
  })

  it('dispatches an optimistic action followed by the final result', () => {
    const thunk = Actions.setCspEnabled('courses', 1, true)
    const fakeDispatch = jest.fn()
    const fakeAxios = {
      put: jest.fn(() => ({
        then(func) {
          const fakeResponse = {data: {enabled: true}}
          func(fakeResponse)
        },
      })),
    }
    thunk(fakeDispatch, null, {axios: fakeAxios})
    expect(fakeDispatch).toHaveBeenNthCalledWith(1, {
      payload: true,
      type: 'SET_CSP_ENABLED_OPTIMISTIC',
    })
    expect(fakeDispatch).toHaveBeenNthCalledWith(2, {
      payload: true,
      type: 'SET_CSP_ENABLED',
    })
  })
})

describe('getCspEnabled', () => {
  it('converts non-plural contexts to plural', () => {
    const thunk = Actions.getCspEnabled('course', 1)
    const fakeDispatch = jest.fn()
    const fakeAxios = {
      get: jest.fn(() => ({then() {}})),
    }
    thunk(fakeDispatch, null, {axios: fakeAxios})
    expect(fakeAxios.get).toHaveBeenCalledWith(expect.stringContaining('courses'))
  })

  it('dispatches a SET_CSP_ENABLED action when complete', () => {
    const thunk = Actions.getCspEnabled('courses', 1)
    const fakeDispatch = jest.fn()
    const fakeAxios = {
      get: jest.fn(() => ({
        then(func) {
          const fakeResponse = {data: {enabled: true}}
          func(fakeResponse)
        },
      })),
    }
    thunk(fakeDispatch, null, {axios: fakeAxios})
    expect(fakeDispatch).toHaveBeenCalledWith({
      payload: true,
      type: 'SET_CSP_ENABLED',
    })
  })
})

describe('addDomainAction', () => {
  it('creates an ADD_DOMAIN action when passed string value', () => {
    expect(Actions.addDomainAction('instructure.com', 'account')).toMatchSnapshot()
  })
  it('creates an error action if passed a non-string value', () => {
    expect(Actions.addDomainAction(true, 'account')).toMatchSnapshot()
  })
  it('creates an error action if given an invalid domainType', () => {
    expect(Actions.addDomainAction('instructure', 'subaccount')).toMatchSnapshot()
  })

  it('creates an ADD_DOMAIN_OPTIMISTIC action when optimistic option is given', () => {
    expect(
      Actions.addDomainAction('instructure.com', 'account', {optimistic: true})
    ).toMatchSnapshot()
  })
})

describe('addDomain', () => {
  it('dispatches an optimistic action followed by the final result', () => {
    const thunk = Actions.addDomain('account', 1, 'instructure.com')
    const fakeDispatch = jest.fn()
    const fakeAxios = {
      post: jest.fn(() => ({
        then(func) {
          const fakeResponse = {}
          func(fakeResponse)
          return {then() {}}
        },
      })),
    }
    thunk(fakeDispatch, null, {axios: fakeAxios})
    expect(fakeDispatch).toHaveBeenNthCalledWith(1, {
      payload: {account: 'instructure.com'},
      type: 'ADD_DOMAIN_OPTIMISTIC',
    })
    expect(fakeDispatch).toHaveBeenNthCalledWith(2, {
      payload: {account: 'instructure.com'},
      type: 'ADD_DOMAIN',
    })
  })

  it('calls the afterAdd function after dispatching', () => {
    const fakeAfterAdd = jest.fn()
    const thunk = Actions.addDomain('account', 1, 'instructure.com', fakeAfterAdd)
    const fakeDispatch = jest.fn()
    const fakeAxios = {
      post: jest.fn(() => ({
        then(func) {
          const fakeResponse = {}
          func(fakeResponse)
          return {
            then(fn) {
              fn()
            },
          }
        },
      })),
    }
    thunk(fakeDispatch, null, {axios: fakeAxios})
    expect(fakeAfterAdd).toHaveBeenCalled()
  })
})

describe('addDomainBulkAction', () => {
  it('creates a ADD_DOMAIN_BULK action when passed an value', () => {
    expect(
      Actions.addDomainBulkAction({
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
    ).toMatchSnapshot()
  })
  it('creates an error action if passed an invalid domainMap', () => {
    expect(
      Actions.addDomainBulkAction({
        lti: ['google.com'],
      })
    ).toMatchSnapshot()
  })
})

describe('getCurrentWhitelist', () => {
  it('dispatches a bulk domain action ', () => {
    const thunk = Actions.getCurrentWhitelist('account', 1)
    const fakeDispatch = jest.fn()
    const fakeGetState = () => ({enabled: true})
    const fakeAxios = {
      get: jest.fn(() => ({
        then(func) {
          const fakeResponse = {
            data: {
              enabled: true,
              current_account_whitelist: ['instructure.com', 'canvaslms.com'],
              effective_whitelist: ['bridgelms.com'],
              tools_whitelist: {
                'lti-tool.com': [
                  {
                    id: '1',
                    name: 'Cool Tool 1',
                    account_id: '1',
                  },
                ],
              },
            },
          }
          func(fakeResponse)
        },
      })),
    }
    thunk(fakeDispatch, fakeGetState, {axios: fakeAxios})
    expect(fakeDispatch).toHaveBeenCalledWith({
      payload: {
        effective: ['bridgelms.com'],
        account: ['instructure.com', 'canvaslms.com'],
        tools: {
          'lti-tool.com': [
            {
              id: '1',
              name: 'Cool Tool 1',
              account_id: '1',
            },
          ],
        },
      },
      type: 'ADD_DOMAIN_BULK',
    })
  })
})

describe('removeDomainAction', () => {
  it('creates an REMOVE_DOMAIN action when passed a string value', () => {
    expect(Actions.removeDomainAction('instructure.com')).toMatchSnapshot()
  })
  it('creates an error action if passed a non-string value', () => {
    expect(Actions.removeDomainAction(false)).toMatchSnapshot()
  })
  it('creates a REMOVE_DOMAIN_OPTIMISTIC action when optimistic option is given', () => {
    expect(Actions.setCspEnabledAction('instructure.com', {optimistic: true})).toMatchSnapshot()
  })
})

describe('removeDomain', () => {
  it('dispatches an optimistic action followed by the final result', () => {
    const thunk = Actions.removeDomain('account', 1, 'instructure.com')
    const fakeDispatch = jest.fn()
    const fakeAxios = {
      delete: jest.fn(() => ({
        then(func) {
          const fakeResponse = {}
          func(fakeResponse)
        },
      })),
    }
    thunk(fakeDispatch, null, {axios: fakeAxios})
    expect(fakeDispatch).toHaveBeenNthCalledWith(1, {
      payload: 'instructure.com',
      type: 'REMOVE_DOMAIN_OPTIMISTIC',
    })
    expect(fakeDispatch).toHaveBeenNthCalledWith(2, {
      payload: 'instructure.com',
      type: 'REMOVE_DOMAIN',
    })
  })
})

describe('setCspInheritedAction', () => {
  it('creates an SET_CSP_INHERITED action when passed a boolean value', () => {
    expect(Actions.setCspInheritedAction(true)).toMatchSnapshot()
  })
  it('creates an error action if passed a non-boolean value', () => {
    expect(Actions.setCspInheritedAction('string')).toMatchSnapshot()
  })
  it('creates a SET_CSP_INHERITED_OPTIMISTIC action when optimistic option is given', () => {
    expect(Actions.setCspInheritedAction(true, {optimistic: true})).toMatchSnapshot()
  })
})

describe('setCspInherited', () => {
  it('dispatches a optimistic value followed by the actual result', () => {
    const thunk = Actions.setCspInherited('account', 1, true)
    const fakeDispatch = jest.fn()
    const fakeGetState = () => ({})
    const fakeAxios = {
      put: jest.fn(() => ({
        then(func) {
          const fakeResponse = {
            data: {
              inherited: true,
            },
          }
          func(fakeResponse)
        },
      })),
    }
    thunk(fakeDispatch, fakeGetState, {axios: fakeAxios})
    expect(fakeDispatch).toHaveBeenNthCalledWith(1, {
      payload: true,
      type: 'SET_CSP_INHERITED_OPTIMISTIC',
    })
    expect(fakeDispatch).toHaveBeenNthCalledWith(2, {
      payload: true,
      type: 'SET_CSP_INHERITED',
    })
  })

  it('updates the enabled status and domain list when successful', () => {
    const thunk = Actions.setCspInherited('account', 1, false)
    const fakeDispatch = jest.fn()
    const fakeGetState = () => ({})
    const fakeAxios = {
      put: jest.fn(() => ({
        then(func) {
          const fakeResponse = {
            data: {
              inherited: true,
              enabled: true,
            },
          }
          func(fakeResponse)
        },
      })),
    }
    thunk(fakeDispatch, fakeGetState, {axios: fakeAxios})
    expect(fakeDispatch).toHaveBeenCalledWith({
      payload: true,
      type: 'SET_CSP_ENABLED',
    })
    expect(fakeDispatch).toHaveBeenCalledWith({
      payload: {effective: [], account: [], tools: {}},
      type: 'ADD_DOMAIN_BULK',
    })
  })

  it('sets the dirty status when cspInherited is true but then switches to false with no account whitelist', () => {
    const thunk = Actions.setCspInherited('account', 1, false)
    const fakeDispatch = jest.fn()
    const fakeGetState = () => ({cspInherited: true})
    const fakeAxios = {
      put: jest.fn(() => ({
        then(func) {
          const fakeResponse = {
            data: {
              inherited: false,
              enabled: true,
              current_account_whitelist: [],
            },
          }
          func(fakeResponse)
        },
      })),
    }
    thunk(fakeDispatch, fakeGetState, {axios: fakeAxios})
    expect(fakeDispatch).toHaveBeenCalledWith({
      payload: true,
      type: 'SET_DIRTY',
    })
  })
})

describe('getCspInherited', () => {
  it('dispatches a SET_CSP_INHERITED action when complete', () => {
    const thunk = Actions.getCspInherited('account', 1)
    const fakeDispatch = jest.fn()
    const fakeAxios = {
      get: jest.fn(() => ({
        then(func) {
          const fakeResponse = {data: {inherited: true}}
          func(fakeResponse)
        },
      })),
    }
    thunk(fakeDispatch, null, {axios: fakeAxios})
    expect(fakeDispatch).toHaveBeenCalledWith({
      payload: true,
      type: 'SET_CSP_INHERITED',
    })
  })
})

describe('setDirtyAction', () => {
  it('creates a SET_DIRTY action when passed a boolean value', () => {
    expect(Actions.setDirtyAction(true)).toMatchSnapshot()
  })
  it('creates an error action if passed a non-boolean value', () => {
    expect(Actions.setDirtyAction('yes')).toMatchSnapshot()
  })
})

describe('copyInheritedAction', () => {
  it('creates a COPY_INHERITED_SUCCESS action', () => {
    expect(Actions.copyInheritedAction([])).toMatchSnapshot()
  })
  it('creates an error action if passed an error param', () => {
    expect(Actions.copyInheritedAction([], new Error('something happened'))).toMatchSnapshot()
  })
})

describe('copyInheritedIfNeeded', () => {
  it('does does nothing if isDirty state is false', () => {
    const thunk = Actions.copyInheritedIfNeeded('account', 1)
    const fakeDispatch = jest.fn()
    const fakeGetState = () => ({
      isDirty: false,
      whitelistedDomains: {inherited: ['canvaslms.com']},
    })
    const fakeAxios = {}
    thunk(fakeDispatch, fakeGetState, {axios: fakeAxios})
    expect(fakeDispatch).not.toHaveBeenCalled()
  })

  it('dispatches a setDirtyAction and a copyInherited action when the request completes', () => {
    const thunk = Actions.copyInheritedIfNeeded('account', 1)
    const fakeDispatch = jest.fn()
    const fakeGetState = () => ({isDirty: true, whitelistedDomains: {inherited: ['canvaslms.com']}})
    const fakeAxios = {
      post: jest.fn(() => ({
        then(func) {
          const fakeResponse = {
            data: {
              inherited: false,
              enabled: true,
              current_account_whitelist: ['canvaslms.com'],
            },
          }
          func(fakeResponse)
        },
      })),
    }
    thunk(fakeDispatch, fakeGetState, {axios: fakeAxios})
    expect(fakeDispatch).toHaveBeenCalledWith({
      payload: false,
      type: 'SET_DIRTY',
    })
    expect(fakeDispatch).toHaveBeenCalledWith({
      payload: ['canvaslms.com'],
      type: 'COPY_INHERITED_SUCCESS',
    })
  })

  it('adds the modifiedDomainOption.add domain to the list of domains to be copied', () => {
    const thunk = Actions.copyInheritedIfNeeded('account', 1, {add: 'instructure.com'})
    const fakeDispatch = jest.fn()
    const fakeGetState = () => ({isDirty: true, whitelistedDomains: {inherited: ['canvaslms.com']}})
    const fakeAxios = {
      post: jest.fn(() => ({
        then: jest.fn(),
      })),
    }
    thunk(fakeDispatch, fakeGetState, {axios: fakeAxios})
    expect(fakeAxios.post).toHaveBeenCalledWith(
      '/api/v1/accounts/1/csp_settings/domains/batch_create',
      {domains: ['canvaslms.com', 'instructure.com']}
    )
  })

  it('removes the modifiedDomainOption.delete domain from the list of domains to be copied', () => {
    const thunk = Actions.copyInheritedIfNeeded('account', 1, {delete: 'instructure.com'})
    const fakeDispatch = jest.fn()
    const fakeGetState = () => ({
      isDirty: true,
      whitelistedDomains: {inherited: ['canvaslms.com', 'instructure.com']},
    })
    const fakeAxios = {
      post: jest.fn(() => ({
        then: jest.fn(),
      })),
    }
    thunk(fakeDispatch, fakeGetState, {axios: fakeAxios})
    expect(fakeAxios.post).toHaveBeenCalledWith(
      '/api/v1/accounts/1/csp_settings/domains/batch_create',
      {domains: ['canvaslms.com']}
    )
  })
})
