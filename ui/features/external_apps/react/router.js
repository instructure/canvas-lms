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
import Root from './components/Root'
import AppList from './components/AppList'
import AppDetails from './components/AppDetails'
import Configurations from './components/Configurations'
import AppCenterStore from './lib/AppCenterStore'

const currentPath = window.location.pathname
const re = /(.*\/settings|.*\/details)/
const matches = re.exec(currentPath)
const baseUrl = matches[0]

let targetNodeToRenderIn = null

/**
 * Route Handlers
 */
const renderAppList = _ctx => {
  if (!window.ENV.APP_CENTER.enabled) {
    page.redirect('/configurations')
  } else {
    ReactDOM.render(
      <Root>
        <AppList baseUrl={baseUrl} />
      </Root>,
      targetNodeToRenderIn
    )
  }
}

const renderAppDetails = ctx => {
  ReactDOM.render(
    <Root>
      <AppDetails shortName={ctx.params.shortName} baseUrl={baseUrl} store={AppCenterStore} />
    </Root>,
    targetNodeToRenderIn
  )
}

const renderConfigurations = _ctx => {
  // router.start is only called when loading the Apps tab
  // so we don't want to try anything here that hasn't happened.
  if (targetNodeToRenderIn) {
    ReactDOM.render(
      <Root>
        <Configurations pathname={baseUrl} env={window.ENV} />
      </Root>,
      targetNodeToRenderIn
    )
  }
}

/**
 * Route Configuration
 */
page.base(baseUrl)
page('/', renderAppList)
page('/app/:shortName', renderAppDetails)
page('/configurations', renderConfigurations)

export default {
  start(targetNode) {
    targetNodeToRenderIn = targetNode
    page.start()
  },
  stop() {
    // we may not be the only thing using page on this page.
    page.stop()
  },
}
