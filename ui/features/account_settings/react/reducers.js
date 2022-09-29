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

import {combineReducers} from 'redux'
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
  WHITELISTS_LOADED,
} from './actions'

export function cspEnabled(state = false, action) {
  switch (action.type) {
    case SET_CSP_ENABLED:
    case SET_CSP_ENABLED_OPTIMISTIC:
      return action.payload
    default:
      return state
  }
}

export function cspInherited(state = false, action) {
  switch (action.type) {
    case SET_CSP_INHERITED:
    case SET_CSP_INHERITED_OPTIMISTIC:
      return action.payload
    default:
      return state
  }
}

export function isDirty(state = false, action) {
  switch (action.type) {
    case SET_DIRTY:
      return action.payload
    default:
      return state
  }
}

export function whitelistsHaveLoaded(state = false, action) {
  switch (action.type) {
    case WHITELISTS_LOADED:
      return action.payload
    default:
      return state
  }
}

function getInheritedList(toolsWhiteList, effectiveWhitelist) {
  const toolsKeys = Object.keys(toolsWhiteList)
  return effectiveWhitelist.filter(domain => !toolsKeys.includes(domain))
}

export function whitelistedDomains(
  state = {account: [], effective: [], inherited: [], tools: {}},
  action
) {
  switch (action.type) {
    case ADD_DOMAIN:
    case ADD_DOMAIN_OPTIMISTIC: {
      const newState = {...state}
      Object.keys(action.payload).forEach(domainType => {
        const uniqueDomains = new Set(state[domainType])
        uniqueDomains.add(action.payload[domainType])
        newState[domainType] = Array.from(uniqueDomains)
      })
      return newState
    }
    case ADD_DOMAIN_BULK: {
      const newState = {...state}
      Object.keys(action.payload).forEach(domainType => {
        if (domainType === 'tools') {
          Object.keys(action.payload[domainType]).forEach(x => {
            newState[domainType][x] = action.payload[domainType][x]
          })
        } else {
          const uniqueDomains = action.reset ? new Set() : new Set(state[domainType])
          action.payload[domainType].forEach(x => uniqueDomains.add(x))
          newState[domainType] = Array.from(uniqueDomains)
        }
      })
      if (newState.tools && newState.effective) {
        newState.inherited = getInheritedList(newState.tools, newState.effective)
      }
      return newState
    }
    case REMOVE_DOMAIN:
    case REMOVE_DOMAIN_OPTIMISTIC: {
      const newState = {...state}
      newState.account = newState.account.filter(domain => domain !== action.payload)
      return newState
    }
    case SET_CSP_INHERITED:
    case SET_CSP_INHERITED_OPTIMISTIC: {
      const newState = {...state}
      if (!newState.account.length) {
        newState.account = newState.inherited
      }
      return newState
    }

    case COPY_INHERITED_SUCCESS: {
      const newState = {...state}
      newState.account = action.payload
      return newState
    }

    default:
      return state
  }
}

export default combineReducers({
  cspEnabled,
  cspInherited,
  isDirty,
  whitelistedDomains,
  whitelistsHaveLoaded,
})
