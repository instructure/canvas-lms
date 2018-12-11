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
      put: jest.fn(() => ({then() {}}))
    }
    thunk(fakeDispatch, null, {axios: fakeAxios})
    expect(fakeAxios.put).toHaveBeenCalledWith(expect.stringContaining('courses'), {
      status: 'enabled'
    })
  })

  it('does not modify plural contexts', () => {
    const thunk = Actions.setCspEnabled('courses', 1, true)
    const fakeDispatch = jest.fn()
    const fakeAxios = {
      put: jest.fn(() => ({then() {}}))
    }
    thunk(fakeDispatch, null, {axios: fakeAxios})
    expect(fakeAxios.put).toHaveBeenCalledWith(expect.stringContaining('courses'), {
      status: 'enabled'
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
        }
      }))
    }
    thunk(fakeDispatch, null, {axios: fakeAxios})
    expect(fakeDispatch).toHaveBeenNthCalledWith(1, {
      payload: true,
      type: 'SET_CSP_ENABLED_OPTIMISTIC'
    })
    expect(fakeDispatch).toHaveBeenNthCalledWith(2, {
      payload: true,
      type: 'SET_CSP_ENABLED'
    })
  })
})

describe('getCspEnabled', () => {
  it('converts non-plural contexts to plural', () => {
    const thunk = Actions.getCspEnabled('course', 1)
    const fakeDispatch = jest.fn()
    const fakeAxios = {
      get: jest.fn(() => ({then() {}}))
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
        }
      }))
    }
    thunk(fakeDispatch, null, {axios: fakeAxios})
    expect(fakeDispatch).toHaveBeenCalledWith({
      payload: true,
      type: 'SET_CSP_ENABLED'
    })
  })
})

describe('addDomainAction', () => {
  it('creates an ADD_DOMAIN action when passed a boolean value', () => {
    expect(Actions.addDomainAction('instructure.com')).toMatchSnapshot()
  })
  it('creates an error action if passed a non-string value', () => {
    expect(Actions.addDomainAction(true)).toMatchSnapshot()
  })
  it('creates an ADD_DOMAIN_OPTIMISTIC action when optimistic option is given', () => {
    expect(Actions.addDomainAction('instructure.com', {optimistic: true})).toMatchSnapshot()
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
        }
      }))
    }
    thunk(fakeDispatch, null, {axios: fakeAxios})
    expect(fakeDispatch).toHaveBeenNthCalledWith(1, {
      payload: 'instructure.com',
      type: 'ADD_DOMAIN_OPTIMISTIC'
    })
    expect(fakeDispatch).toHaveBeenNthCalledWith(2, {
      payload: 'instructure.com',
      type: 'ADD_DOMAIN'
    })
  })
})

describe('addDomainBulkAction', () => {
  it('creates a ADD_DOMAIN action when passed an value', () => {
    expect(Actions.addDomainBulkAction(['instructure.com', 'canvaslms.com'])).toMatchSnapshot()
  })
  it('creates an error action if passed a non-Array value', () => {
    expect(Actions.addDomainBulkAction('instructure.com')).toMatchSnapshot()
  })
})

describe('getCurrentWhitelist', () => {
  it('dispatches a bulk domain action using the effective_whitelist when the whitelist is enabled', () => {
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
              effective_whitelist: ['bridgelms.com']
            }
          }
          func(fakeResponse)
        }
      }))
    }
    thunk(fakeDispatch, fakeGetState, {axios: fakeAxios})
    expect(fakeDispatch).toHaveBeenCalledWith({
      payload: ['bridgelms.com'],
      type: 'ADD_DOMAIN_BULK'
    })
  })

  it('dispatches a bulk domain action using the current_account_whitelist when the whitelist is disabled', () => {
    const thunk = Actions.getCurrentWhitelist('account', 1)
    const fakeDispatch = jest.fn()
    const fakeGetState = () => ({enabled: false})
    const fakeAxios = {
      get: jest.fn(() => ({
        then(func) {
          const fakeResponse = {
            data: {
              enabled: false,
              current_account_whitelist: ['instructure.com', 'canvaslms.com'],
              effective_whitelist: ['bridgelms.com']
            }
          }
          func(fakeResponse)
        }
      }))
    }
    thunk(fakeDispatch, fakeGetState, {axios: fakeAxios})
    expect(fakeDispatch).toHaveBeenCalledWith({
      payload: ['instructure.com', 'canvaslms.com'],
      type: 'ADD_DOMAIN_BULK'
    })
  })
})
