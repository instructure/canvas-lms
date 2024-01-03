/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import {map, sortBy, filter, forEach, find} from 'lodash'
import createStore from './createStoreJestCompatible'
import parseLinkHeader from 'link-header-parsing/parseLinkHeaderFromXHR'
import '@canvas/rails-flash-notifications'

const I18n = useI18nScope('external_tools')

const PER_PAGE = 50

const sort = function (tools) {
  if (tools) {
    return sortBy(tools, tool => {
      if (tool.name) {
        return tool.name.toUpperCase()
      } else {
        return 'ZZZZZZZZZZ' // end of sort list
      }
    })
  } else {
    return []
  }
}

const defaultState = {
  externalTools: [],
  links: {},
  isLoading: false, // flag to indicate fetch is in progress
  isLoaded: false, // flag to indicate data has loaded
  hasMore: false, // flag to indicate if there are more pages of external tools
  lastReset: 0, // time of last reset. if a reset happens while waiting for an
  // AJAX request, we will ignore the response
}

const store = createStore(defaultState)

store.reset = function () {
  this.setState({...defaultState, lastReset: window.performance.now()})
}

store.fetch = function () {
  if (this.getState().isLoading) {
    return
  }
  const lastReset = this.getState().lastReset
  const self = this
  const url =
    this.getState().links.next ||
    '/api/v1' + ENV.CONTEXT_BASE_URL + '/lti_apps?per_page=' + PER_PAGE
  this.setState({isLoading: true})
  $.ajax({
    url,
    type: 'GET',
    success: (tools, status, xhr) =>
      this._fetchSuccessHandler.call(self, tools, status, xhr, lastReset),
    error: () => this._fetchErrorHandler.call(self, lastReset),
  })
}

store.fetchWithDetails = function (tool) {
  if (tool.app_type === 'ContextExternalTool') {
    return $.getJSON(
      '/api/v1/' +
        tool.context.toLowerCase() +
        's/' +
        tool.context_id +
        '/external_tools/' +
        tool.app_id
    )
  } else {
    // DOES NOT EXIST YET
    return $.getJSON('/api/v1' + ENV.CONTEXT_BASE_URL + '/tool_proxies/' + tool.app_id)
  }
}

store.togglePlacements = function ({tool, placements, onSuccess = () => {}, onError = () => {}}) {
  const data = {
    // include this always, since it will only change for
    // 1.1 tools toggling default placements
    not_selectable: tool.not_selectable,
  }
  for (const p of placements) {
    data[p] = {enabled: tool[p].enabled}
  }

  $.ajax({
    url: `/api/v1/${tool.context.toLowerCase()}s/${tool.context_id}/external_tools/${tool.app_id}`,
    data,
    type: 'PUT',
    success: onSuccess.bind(this),
    error: onError.bind(this),
  })
}

store.save = function (configurationType, data, success, error) {
  configurationType = configurationType || 'manual'

  const params = this._generateParams(configurationType, data)

  // Don't send shared secret if it hasn't changed //
  if (params.shared_secret === 'N/A') {
    delete params.shared_secret
  }

  let url = '/api/v1' + ENV.CONTEXT_BASE_URL + '/external_tools'
  let method = 'POST'
  if (data.app_id) {
    url = '/api/v1' + ENV.CONTEXT_BASE_URL + '/external_tools/' + data.app_id
    method = 'PUT'
  }
  $.ajax({
    url,
    contentType: 'application/json',
    data: JSON.stringify({external_tool: params}),
    type: method,
    success: success.bind(this),
    error: error.bind(this),
  })
}

store.setAsFavorite = function (tool, isFavorite, success, error) {
  const url = '/api/v1' + ENV.CONTEXT_BASE_URL + '/external_tools/rce_favorites/' + tool.app_id
  const method = isFavorite ? 'POST' : 'DELETE'

  $.ajax({
    url,
    contentType: 'application/json',
    type: method,
    success: success.bind(this),
    error: error.bind(this),
  })
}

store.updateAccessToken = function (context_base_url, accessToken, success, error) {
  $.ajax({
    url: context_base_url,
    dataType: 'json',
    type: 'PUT',
    data: {account: {settings: {app_center_access_token: accessToken}}},
    success: success.bind(this),
    error: error.bind(this),
  })
}

store.delete = function (tool) {
  let url

  if (tool.app_type === 'ContextExternalTool') {
    url = '/api/v1' + ENV.CONTEXT_BASE_URL + '/external_tools/' + tool.app_id
  } else {
    // Lti::ToolProxy
    url = '/api/v1' + ENV.CONTEXT_BASE_URL + '/tool_proxies/' + tool.app_id
  }

  const tools = filter(this.getState().externalTools, t => t.app_id !== tool.app_id)
  this.setState({externalTools: sort(tools)})

  $.ajax({
    url,
    type: 'DELETE',
    success: this._deleteSuccessHandler.bind(this),
    error: this._deleteErrorHandler.bind(this),
  })
}

function handleToolUpdate(tool, dismiss = false) {
  if (tool.app_type === 'ContextExternalTool') {
    // we dont support LTI 1
    return
  }

  const url = '/api/v1' + ENV.CONTEXT_BASE_URL + '/tool_proxies/' + tool.app_id + '/update',
    errorHandler = dismiss ? this._dismissUpdateErrorHandler : this._acceptUpdateErrorHandler
  tool.has_update = false
  this.setState({externalTools: sort(this.getState().externalTools)})

  $.ajax({
    url,
    type: dismiss ? 'DELETE' : 'PUT',
    success: this._genericSuccessHandler.bind(this),
    error: errorHandler.bind(this),
  })
}

store.acceptUpdate = function (tool) {
  handleToolUpdate.call(this, tool)
}

store.dismissUpdate = function (tool) {
  handleToolUpdate.call(this, tool, true)
}

store.triggerUpdate = function () {
  this.setState({externalTools: sort(this.getState().externalTools)})
}

store.activate = function (tool, success, error) {
  const url = '/api/v1' + ENV.CONTEXT_BASE_URL + '/tool_proxies/' + tool.app_id
  const tools = map(this.getState().externalTools, t => {
    if (t.app_id === tool.app_id) {
      t.enabled = true
    }
    return t
  })
  this.setState({externalTools: sort(tools)})

  $.ajax({
    url,
    data: {workflow_state: 'active'},
    type: 'PUT',
    success: success.bind(this),
    error: error.bind(this),
  })
}

store.deactivate = function (tool, success, error) {
  const tools = map(this.getState().externalTools, t => {
    if (t.app_id === tool.app_id) {
      t.enabled = false
    }
    return t
  })
  this.setState({externalTools: sort(tools)})

  $.ajax({
    url: '/api/v1' + ENV.CONTEXT_BASE_URL + '/tool_proxies/' + tool.app_id,
    data: {workflow_state: 'disabled'},
    type: 'PUT',
    success: success.bind(this),
    error: error.bind(this),
  })
}

store.findById = function (toolId) {
  return find(this.getState().externalTools, tool => tool.app_id === toolId)
}

store._generateParams = function (configurationType, data) {
  const params = {}
  params.name = data.name
  params.privacy_level = 'anonymous'
  params.consumer_key = 'N/A'
  params.shared_secret = 'N/A'
  params.verify_uniqueness = data.verifyUniqueness
  if (data.consumerKey && data.consumerKey.length > 0) {
    params.consumer_key = data.consumerKey
  }
  if (data.sharedSecret && data.sharedSecret.length > 0) {
    params.shared_secret = data.sharedSecret
  }
  switch (configurationType) {
    case 'manual':
      // Convert custom fields into kv pair
      if (data.customFields === '' || typeof data.customFields === 'undefined') {
        params.custom_fields_string = ''
      } else {
        const pairs = (data.customFields || '').split('\n')
        params.custom_fields = {}
        forEach(pairs, pair => {
          const vals = pair.trim().split(/=(.+)?/)
          params.custom_fields[vals[0]] = vals[1]
        })
      }

      params.domain = data.domain
      params.privacy_level = data.privacyLevel
      params.url = data.url
      params.description = data.description
      break
    case 'url':
      params.config_type = 'by_url'
      params.config_url = data.configUrl
      break
    case 'xml':
      params.config_type = 'by_xml'
      params.config_xml = data.xml
      break
  }

  if (data.allow_membership_service_access != null) {
    params.allow_membership_service_access = data.allow_membership_service_access
  }

  return params
}

//* ** CALLBACK HANDLERS ***/

store._fetchSuccessHandler = function (tools, status, xhr, lastReset) {
  if (this.getState().lastReset > lastReset) {
    return
  }

  const links = parseLinkHeader(xhr)
  tools = this.getState().externalTools.concat(tools)

  this.setState({
    links,
    isLoading: false,
    isLoaded: true,
    externalTools: sort(tools),
    hasMore: !!links.next,
  })
}

store._fetchErrorHandler = function (lastReset) {
  if (this.getState().lastReset > lastReset) {
    return
  }

  this.setState({
    isLoading: false,
    isLoaded: false,
    externalTools: [],
    hasMore: false,
  })
}

store._genericSuccessHandler = store._deleteSuccessHandler = function () {
  // noop
}

store._deleteErrorHandler = function () {
  $.flashError(I18n.t('Unable to remove app'))
  this.fetch({force: true})
}

store._acceptUpdateErrorHandler = function () {
  $.flashError(I18n.t('Unable to accept update'))
  this.fetch({force: true})
}

store._dismissUpdateErrorHandler = function () {
  $.flashError(I18n.t('Unable to dismiss update'))
  this.fetch({force: true})
}

export default store
