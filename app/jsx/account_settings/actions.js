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

export const SET_CSP_ENABLED = 'SET_CSP_ENABLED'
export const SET_CSP_ENABLED_OPTIMISTIC = 'SET_CSP_ENABLED_OPTIMISTIC'

export function setCspEnabledAction(value, opts = {}) {
  const type = opts.optimistic ? SET_CSP_ENABLED_OPTIMISTIC : SET_CSP_ENABLED
  if (typeof value !== 'boolean') {
    return {
      type,
      payload: new Error('Can only set to Boolean values'),
      error: true
    }
  }
  return {
    type,
    payload: value
  }
}

export function setCspEnabled(context, contextId, value) {
  context = pluralize(context)
  return (dispatch, getState, {axios}) => {
    dispatch(setCspEnabledAction(value, {optimistic: true}))
    return axios
      .put(`/api/v1/${context}/${contextId}/csp_settings`, {
        status: value ? 'enabled' : 'disabled'
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
