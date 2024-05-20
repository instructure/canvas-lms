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
import $ from 'jquery'
import page from 'page'
import qs from 'qs'
import CollaborationsApp from './CollaborationsApp'
import CollaborationsToolLaunch from './CollaborationsToolLaunch'
import actions from './actions'
import store from './store'
import {isValidDeepLinkingEvent} from '@canvas/deep-linking/DeepLinking'
import processSingleContentItem from '@canvas/deep-linking/processors/processSingleContentItem'
import {handleExternalContentMessages} from '@canvas/external-tools/messages'


const attachListeners = () => {
  // LTI 1.3 deep linking handler
  window.addEventListener('message', async event => {
    // Don't attempt to process invalid messages
    if (!isValidDeepLinkingEvent(event, ENV)) {
      return
    }

    try {
      const item = processSingleContentItem(event)
      store.dispatch(
        actions.externalContentReady({
          service_id: event.data?.service_id,
          contentItems: [item],
          tool_id: event.data?.tool_id,
        })
      )
    } catch {
      store.dispatch(actions.externalContentRetrievalFailed)
    }
  })

  // called by LTI 1.1 content item handler
  handleExternalContentMessages({
    ready: (data) => {
      store.dispatch(actions.externalContentReady(data))
    }
  })
}

let unsubscribe
/**
 * Route Handlers
 */
function renderShowCollaborations(ctx) {
  store.dispatch(actions.getLTICollaborators(ctx.params.context, ctx.params.contextId))
  store.dispatch(
    actions.getCollaborations(
      `/api/v1/${ctx.params.context}/${ctx.params.contextId}/collaborations`,
      true
    )
  )

  const view = () => {
    const state = store.getState()
    ReactDOM.render(
      <CollaborationsApp applicationState={state} actions={actions} />,
      document.getElementById('content')
    )
  }
  unsubscribe = store.subscribe(view)
  view()
}

function renderLaunchTool(ctx) {
  const view = () => {
    ReactDOM.render(
      <CollaborationsToolLaunch launchUrl={ctx.path.replace('/lti_collaborations', '')} />,
      document.getElementById('content')
    )
  }
  view()
}

/**
 * Middlewares
 */

function parseQueryString(ctx, next) {
  ctx.query = qs.parse(ctx.querystring)
  next()
}

/**
 * Route Configuration
 */
page('*', parseQueryString) // Middleware to parse querystring to object

page('/:context(courses|groups)/:contextId/lti_collaborations', renderShowCollaborations)
page.exit('/:context(courses|groups)/:contextId/lti_collaborations', (ctx, next) => {
  unsubscribe()
  next()
})

page('/:context(courses|groups)/:contextId/lti_collaborations/external_tools*', renderLaunchTool)

export default {
  start() {
    attachListeners()
    page.start()
  },
  attachListeners,
}
