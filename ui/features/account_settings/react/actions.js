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

function pluralize(word) {
  if (word[word.length - 1] !== 's') {
    return `${word}s`
  }
  return word
}

export const WHITELISTS_LOADED = 'WHITELISTS_LOADED'
export function setWhitelistsLoaded(value) {
  return {type: WHITELISTS_LOADED, payload: value}
}

export const SET_DIRTY = 'SET_DIRTY'
export function setDirtyAction(value) {
  if (typeof value !== 'boolean') {
    return {
      type: SET_DIRTY,
      payload: new Error('Can only set to Boolean values'),
      error: true,
    }
  }
  return {
    type: SET_DIRTY,
    payload: value,
  }
}

export const SET_CSP_ENABLED = 'SET_CSP_ENABLED'
export const SET_CSP_ENABLED_OPTIMISTIC = 'SET_CSP_ENABLED_OPTIMISTIC'

export function setCspEnabledAction(value, opts = {}) {
  const type = opts.optimistic ? SET_CSP_ENABLED_OPTIMISTIC : SET_CSP_ENABLED
  if (typeof value !== 'boolean') {
    return {
      type,
      payload: new Error('Can only set to Boolean values'),
      error: true,
    }
  }
  return {
    type,
    payload: value,
  }
}

export function setCspEnabled(context, contextId, value) {
  context = pluralize(context)
  return (dispatch, getState, {axios}) => {
    dispatch(setCspEnabledAction(value, {optimistic: true}))
    return axios
      .put(`/api/v1/${context}/${contextId}/csp_settings`, {
        status: value ? 'enabled' : 'disabled',
      })
      .then(response => {
        dispatch(setCspEnabledAction(response.data.enabled))
      })
  }
}

export function getCspEnabled(context, contextId) {
  context = pluralize(context)
  return (dispatch, getState, {axios}) =>
    axios.get(`/api/v1/${context}/${contextId}/csp_settings`).then(response => {
      dispatch(setCspEnabledAction(response.data.enabled))
    })
}

export const SET_CSP_INHERITED = 'SET_CSP_INHERITED'
export const SET_CSP_INHERITED_OPTIMISTIC = 'SET_CSP_INHERITED_OPTIMISTIC'

export function setCspInheritedAction(value, opts = {}) {
  const type = opts.optimistic ? SET_CSP_INHERITED_OPTIMISTIC : SET_CSP_INHERITED
  if (typeof value !== 'boolean') {
    return {
      type,
      payload: new Error('Can only set to Boolean values'),
      error: true,
    }
  }
  return {
    type,
    payload: value,
  }
}

export function setCspInherited(context, contextId, value) {
  context = pluralize(context)
  return (dispatch, getState, {axios}) => {
    const {cspEnabled, cspInherited} = getState()
    dispatch(setCspInheritedAction(value, {optimistic: true}))
    return axios
      .put(`/api/v1/${context}/${contextId}/csp_settings`, {
        status: value ? 'inherited' : cspEnabled ? 'enabled' : 'disabled',
      })
      .then(response => {
        // Set the actual inherited status
        dispatch(setCspInheritedAction(response.data.inherited))
        // Because changing if you inherit or not can also affect
        // the enabled status, we also do an update there as well
        // to be safe.
        dispatch(setCspEnabledAction(response.data.enabled))
        // Likewise changing the inherited status likely has an effect
        // on what domains are allowed, so we update those as well.
        const addDomainMap = {
          effective: response.data.effective_whitelist || [],
          account: response.data.current_account_whitelist || [],
          tools: response.data.tools_whitelist || {},
        }
        dispatch(addDomainBulkAction(addDomainMap, {reset: !cspInherited && value}))
        // Set the dirty status if needed, this will help us know if
        // we need to copy their stuff over on add/delete
        if (cspInherited && !value && addDomainMap.account.length === 0) {
          dispatch(setDirtyAction(true))
        }
      })
  }
}

export function getCspInherited(context, contextId) {
  context = pluralize(context)
  return (dispatch, getState, {axios}) =>
    axios.get(`/api/v1/${context}/${contextId}/csp_settings`).then(response => {
      dispatch(setCspInheritedAction(response.data.inherited))
    })
}

export const ADD_DOMAIN = 'ADD_DOMAIN'
export const ADD_DOMAIN_BULK = 'ADD_DOMAIN_BULK'
export const ADD_DOMAIN_OPTIMISTIC = 'ADD_DOMAIN_OPTIMISTIC'
const DOMAIN_MAP_KEYS = ['account', 'tools', 'effective']

export function addDomainAction(domain, domainType, opts = {}) {
  const type = opts.optimistic ? ADD_DOMAIN_OPTIMISTIC : ADD_DOMAIN
  if (typeof domain !== 'string') {
    return {
      type,
      payload: new Error('Can only set to String values'),
      error: true,
    }
  }
  if (!DOMAIN_MAP_KEYS.includes(domainType)) {
    return {
      type,
      payload: new Error('domainType is invalid'),
      error: true,
    }
  }
  return {
    type,
    payload: {[domainType]: domain},
  }
}

export function addDomainBulkAction(domainsMap, opts = {}) {
  if (Object.keys(domainsMap).some(d => !DOMAIN_MAP_KEYS.includes(d))) {
    return {
      type: ADD_DOMAIN_BULK,
      payload: new Error('Invalid domain type key provided in domainsMap'),
      error: true,
    }
  }
  if (opts.reset) {
    return {
      type: ADD_DOMAIN_BULK,
      payload: domainsMap,
      reset: true,
    }
  }
  return {
    type: ADD_DOMAIN_BULK,
    payload: domainsMap,
  }
}

export function addDomain(context, contextId, domain, afterAdd = () => {}) {
  context = pluralize(context)
  return (dispatch, getState, {axios}) => {
    dispatch(addDomainAction(domain, 'account', {optimistic: true}))
    return axios
      .post(`/api/v1/${context}/${contextId}/csp_settings/domains`, {
        domain,
      })
      .then(() => {
        // This isn't really necessary but since the allowed domain list is unique,
        // it doesn't hurt.
        dispatch(addDomainAction(domain, 'account'))
      })
      .then(afterAdd)
  }
}

export function getCurrentWhitelist(context, contextId) {
  context = pluralize(context)
  return (dispatch, getState, {axios}) =>
    axios.get(`/api/v1/${context}/${contextId}/csp_settings`).then(response => {
      const addDomainMap = {
        effective: response.data.effective_whitelist || [],
        account: response.data.current_account_whitelist || [],
        tools: response.data.tools_whitelist || {},
      }
      dispatch(addDomainBulkAction(addDomainMap))
      dispatch(setWhitelistsLoaded(true))
    })
}

export const REMOVE_DOMAIN = 'REMOVE_DOMAIN'
export const REMOVE_DOMAIN_OPTIMISTIC = 'REMOVE_DOMAIN_OPTIMISTIC'

export function removeDomainAction(domain, opts = {}) {
  const type = opts.optimistic ? REMOVE_DOMAIN_OPTIMISTIC : REMOVE_DOMAIN
  if (typeof domain !== 'string') {
    return {
      type,
      payload: new Error('Domain can only set to String values'),
      error: true,
    }
  }
  return {
    type,
    payload: domain,
  }
}

export function removeDomain(context, contextId, domain) {
  context = pluralize(context)
  return (dispatch, getState, {axios}) => {
    dispatch(removeDomainAction(domain, {optimistic: true}))
    return axios
      .delete(`/api/v1/${context}/${contextId}/csp_settings/domains?domain=${domain}`)
      .then(() => {
        // This isn't really necessary but doesn't hurt
        dispatch(removeDomainAction(domain))
      })
  }
}

export const COPY_INHERITED_SUCCESS = 'COPY_INHERITED_SUCCESS'
export const COPY_INHERITED_FAILURE = 'COPY_INHERITED_FAILURE'

export function copyInheritedAction(newWhitelist, error) {
  if (error) {
    return {
      type: COPY_INHERITED_FAILURE,
      payload: new Error(error),
      error: true,
    }
  }
  return {
    type: COPY_INHERITED_SUCCESS,
    payload: newWhitelist,
  }
}

export function copyInheritedIfNeeded(context, contextId, modifiedDomainOption = {}) {
  context = pluralize(context)
  return (dispatch, getState, {axios}) => {
    if (getState().isDirty) {
      let domains = getState().whitelistedDomains.inherited
      if (modifiedDomainOption.add) {
        domains.push(modifiedDomainOption.add)
      }
      if (modifiedDomainOption.delete) {
        domains = domains.filter(d => d !== modifiedDomainOption.delete)
      }
      return axios
        .post(`/api/v1/${context}/${contextId}/csp_settings/domains/batch_create`, {
          domains,
        })
        .then(response => {
          dispatch(setDirtyAction(false))
          dispatch(copyInheritedAction(response.data.current_account_whitelist))
        })
    }
  }
}
