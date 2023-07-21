/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import ReactDOM from 'react-dom'
import page from 'page'
import qs from 'qs'
import filesEnv from '@canvas/files/react/modules/filesEnv'
import FilesApp from './react/components/FilesApp'
import ShowFolder from './react/components/ShowFolder'
import SearchResults from './react/components/SearchResults'

/**
 * Route Handlers
 */
function renderShowFolder(ctx) {
  ReactDOM.render(
    <FilesApp
      query={ctx.query}
      params={ctx.params}
      splat={ctx.splat}
      pathname={ctx.pathname}
      contextAssetString={window.ENV.context_asset_string}
    >
      <ShowFolder />
    </FilesApp>,
    document.getElementById('content')
  )
}

function renderSearchResults(ctx) {
  ReactDOM.render(
    <FilesApp
      query={ctx.query}
      params={ctx.params}
      splat={ctx.splat}
      pathname={ctx.pathname}
      contextAssetString={window.ENV.context_asset_string}
    >
      <SearchResults />
    </FilesApp>,
    document.getElementById('content')
  )
}

/**
 * Middlewares
 */

function parseQueryString(ctx, next) {
  ctx.query = qs.parse(ctx.querystring)
  next()
}

function getFolderSplat(ctx, next) {
  /* This function only gets called when hitting the /folder/*
   * route so we make that assumption here with many of the
   * things being done.
   */
  const PATH_PREFIX = '/folder/'
  const index = ctx.pathname.indexOf(PATH_PREFIX) + PATH_PREFIX.length
  const rawSplat = ctx.pathname.slice(index)
  ctx.splat = rawSplat
    .split('/')
    .map(part => window.encodeURIComponent(part))
    .join('/')
  next()
}

function getSplat(ctx, next) {
  ctx.splat = ''
  next()
}

/**
 * Route Configuration
 */
page.base(filesEnv.baseUrl)
page('*', getSplat) // Generally this will overridden by the folder route's middleware
page('*', parseQueryString) // Middleware to parse querystring to object
page('/', renderShowFolder)
page('/search', renderSearchResults)
page('/folder', '/')
page('/folder/*', getFolderSplat, renderShowFolder)

export default {
  start() {
    page.start({click: false})
  },
  getFolderSplat, // Export getSplat for testing
}
