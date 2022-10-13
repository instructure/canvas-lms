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

import {cspEnabled, whitelistedDomains, cspInherited, isDirty} from '../reducers'
import {
  SET_CSP_ENABLED,
  SET_CSP_ENABLED_OPTIMISTIC,
  ADD_DOMAIN,
  ADD_DOMAIN_OPTIMISTIC,
  ADD_DOMAIN_BULK,
  REMOVE_DOMAIN,
  REMOVE_DOMAIN_OPTIMISTIC,
  SET_CSP_INHERITED,
  SET_CSP_INHERITED_OPTIMISTIC,
  SET_DIRTY,
  COPY_INHERITED_SUCCESS,
} from '../actions'

describe('cspEnabled', () => {
  const testMatrix = [
    [{type: SET_CSP_ENABLED, payload: true}, undefined, true],
    [{type: SET_CSP_ENABLED_OPTIMISTIC, payload: false}, undefined, false],
  ]
  it.each(testMatrix)(
    'with %p action and %p value the cspEnabled state becomes %p',
    (action, initialState, expectedState) => {
      expect(cspEnabled(initialState, action)).toEqual(expectedState)
    }
  )
})

describe('whitelistedDomains', () => {
  const testMatrix = [
    [{type: ADD_DOMAIN, payload: {account: 'instructure.com'}}, [], {account: ['instructure.com']}],
    [
      {type: ADD_DOMAIN_OPTIMISTIC, payload: {account: 'instructure.com'}},
      [],
      {account: ['instructure.com']},
    ],
  ]
  it.each(testMatrix)(
    'with %p action and %p payload the whitelistedDomains state becomes %p',
    (action, initialState, expectedState) => {
      expect(whitelistedDomains(initialState, action)).toEqual(expectedState)
    }
  )

  it('does not allow duplicate domains with ADD_DOMAIN actions', () => {
    const action = {type: ADD_DOMAIN, payload: {account: 'instructure.com'}}
    const initialState = {account: ['instructure.com', 'canvaslms.com']}
    expect(whitelistedDomains(initialState, action)).toEqual({
      account: ['instructure.com', 'canvaslms.com'],
    })
  })

  it('does not allow duplicates domains with ADD_DOMAIN_BULK actions', () => {
    const action = {type: ADD_DOMAIN_BULK, payload: {account: ['instructure.com', 'bridgelms.com']}}
    const initialState = {account: ['instructure.com', 'canvaslms.com']}
    expect(whitelistedDomains(initialState, action)).toEqual({
      account: ['instructure.com', 'canvaslms.com', 'bridgelms.com'],
    })
  })

  it('handles bulk adding of tools domains with ADD_DOMAIN_BULK actions', () => {
    const action = {
      type: ADD_DOMAIN_BULK,
      payload: {
        tools: {
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
        },
      },
    }
    const initialState = {account: ['instructure.com', 'canvaslms.com'], tools: {}}

    expect(whitelistedDomains(initialState, action)).toEqual({
      account: ['instructure.com', 'canvaslms.com'],
      tools: {
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
      },
    })
  })

  it('removes domains with REMOVE_DOMAIN actions', () => {
    const action = {type: REMOVE_DOMAIN, payload: 'instructure.com'}
    const initialState = {account: ['instructure.com', 'canvaslms.com']}
    expect(whitelistedDomains(initialState, action)).toEqual({
      account: ['canvaslms.com'],
    })
  })

  it('removes domains with REMOVE_DOMAIN_OPTIMISTIC actions', () => {
    const action = {type: REMOVE_DOMAIN_OPTIMISTIC, payload: 'instructure.com'}
    const initialState = {account: ['instructure.com', 'canvaslms.com']}
    expect(whitelistedDomains(initialState, action)).toEqual({
      account: ['canvaslms.com'],
    })
  })

  it('creates a list of inherited domains given a list of tool domains and effective domains on ADD_DOMAIN_BULK', () => {
    const action = {
      type: ADD_DOMAIN_BULK,
      payload: {
        tools: {
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
        },
        effective: ['instructure.com', 'bridgelms.com', 'arcmedia.com', 'canvaslms.com'],
      },
    }
    expect(whitelistedDomains(undefined, action).inherited).toEqual([
      'arcmedia.com',
      'canvaslms.com',
    ])
  })

  it('clears the initial state before adding domains with ADD_DOMAIN_BULK if action.reset is true', () => {
    const action = {
      type: ADD_DOMAIN_BULK,
      payload: {
        account: ['google.com', 'facebook.com'],
      },
      reset: true,
    }
    const initialState = {
      account: ['instructure.com', 'canvaslms.com', 'arcmedia.com'],
    }
    expect(whitelistedDomains(initialState, action)).toEqual({
      account: ['google.com', 'facebook.com'],
    })
  })

  describe('SET_CSP_INHERITED', () => {
    it('sets the account state to the inherited state if the account state is empty', () => {
      const action = {type: SET_CSP_INHERITED}

      const initialState = {
        account: [],
        inherited: ['instructure.com', 'canvaslms.com'],
      }

      expect(whitelistedDomains(initialState, action)).toEqual({
        account: ['instructure.com', 'canvaslms.com'],
        inherited: ['instructure.com', 'canvaslms.com'],
      })
    })
    it('does not set the account state if the account state is not empty', () => {
      const action = {type: SET_CSP_INHERITED}

      const initialState = {
        account: ['bridgelms.com'],
        inherited: ['instructure.com', 'canvaslms.com'],
      }

      expect(whitelistedDomains(initialState, action)).toEqual(initialState)
    })
  })

  it('sets the account state to the payload of a COPY_INHERITED_SUCCESS action', () => {
    const action = {type: COPY_INHERITED_SUCCESS, payload: ['canvaslms.com', 'bridgelms.com']}
    expect(whitelistedDomains(undefined, action).account).toEqual(action.payload)
  })
})

describe('cspInherited', () => {
  const testMatrix = [
    [{type: SET_CSP_INHERITED, payload: true}, undefined, true],
    [{type: SET_CSP_INHERITED_OPTIMISTIC, payload: false}, undefined, false],
  ]
  it.each(testMatrix)(
    'with %p action and %p value the cspInherited state becomes %p',
    (action, initialState, expectedState) => {
      expect(cspInherited(initialState, action)).toEqual(expectedState)
    }
  )
})

describe('setDirty', () => {
  it.each([
    [{type: SET_DIRTY, payload: true}, undefined, true],
    [{type: SET_DIRTY, payload: false}, undefined, false],
  ])(
    'with %p action and %p initial state the isDirty state becomes %p',
    (action, initialState, expectedState) => {
      expect(isDirty(initialState, action)).toEqual(expectedState)
    }
  )
})
