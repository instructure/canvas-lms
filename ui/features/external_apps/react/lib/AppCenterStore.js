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

import $ from 'jquery'
import {find, sortBy, filter as lodashFilter} from 'lodash'
import createStore from './createStoreJestCompatible'
import ExternalAppsStore from './ExternalAppsStore'
import parseLinkHeader from 'link-header-parsing/parseLinkHeaderFromXHR'
import '@canvas/rails-flash-notifications'

const PER_PAGE = 250

const sort = function (apps) {
  if (apps) {
    return sortBy(apps, app => {
      if (app.name) {
        return app.name.toUpperCase()
      } else {
        return 'ZZZZZZZZZZ' // end of sort list
      }
    })
  } else {
    return []
  }
}

const defaultState = {
  isLoading: false, // flag to indicate fetch is in progress
  isLoaded: false, // flag to indicate if fetch should re-pull if already pulled
  apps: [],
  links: {},
  filter: 'all',
  filterText: '',
  hasMore: false, // flag to indicate if there are more pages of external tools
}

const store = createStore(defaultState)

store.reset = function () {
  this.setState(defaultState)
}

store.fetch = function () {
  const url =
    this.getState().links.next ||
    `/api/v1${ENV.CONTEXT_BASE_URL}/app_center/apps?per_page=${PER_PAGE}`
  this.setState({isLoading: true})
  $.ajax({
    url,
    type: 'GET',
    success: this._fetchSuccessHandler.bind(this),
    error: this._fetchErrorHandler.bind(this),
  })
}

store.filteredApps = function (toFilter = this.getState().apps) {
  const filter = this.getState().filter
  const filterText = new RegExp(this.getState().filterText, 'i')

  return lodashFilter(toFilter, app => {
    if (!app.name) {
      return false
    }

    const isInstalled = !!app.is_installed
    const name = app.name
    const categories = app.categories || []

    if (filter === 'installed' && !isInstalled) {
      return false
    } else if (filter === 'not_installed' && isInstalled) {
      return false
    }

    return name.match(filterText) || categories.join().match(filterText)
  })
}

store.findAppByShortName = function (shortName) {
  return find(this.getState().apps, app => app.short_name === shortName)
}

store.flagAppAsInstalled = function (shortName) {
  // eslint-disable-next-line lodash/collection-return, , lodash/collection-method-value
  find(this.getState().apps, app => {
    if (app.short_name === shortName) {
      app.is_installed = true
    }
  })
}

// *** CALLBACK HANDLERS ***/

store._fetchSuccessHandler = function (apps, status, xhr) {
  const links = parseLinkHeader(xhr)
  let tools = apps
  if (links.current !== links.first) {
    tools = this.getState().apps.concat(apps)
  }

  this.setState({
    links,
    isLoading: false,
    isLoaded: true,
    apps: sort(tools),
    hasMore: !!links.next,
  })

  // Update the installed app list in case this is a reload from
  // installing a tool from the app center
  ExternalAppsStore.reset()
  ExternalAppsStore.fetch()
}

store._fetchErrorHandler = function () {
  this.setState({
    isLoading: false,
    isLoaded: false,
    apps: [],
    hasMore: true,
  })
}

export default store
