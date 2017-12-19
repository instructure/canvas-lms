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
import redux from 'redux'
import CollaborationsApp from '../collaborations/CollaborationsApp'
import CollaborationsToolLaunch from '../collaborations/CollaborationsToolLaunch'
import actions from '../collaborations/actions/collaborationsActions'
import store from '../collaborations/store/store'
import splitAssetString from 'compiled/str/splitAssetString'

  $(window).on('externalContentReady', (e, data) => store.dispatch(actions.externalContentReady(e, data)));

  let unsubscribe
  /**
   * Route Handlers
   */
  function renderShowCollaborations (ctx) {
    store.dispatch(actions.getLTICollaborators(ctx.params.context, ctx.params.contextId));
    store.dispatch(actions.getCollaborations(`/api/v1/${ctx.params.context}/${ctx.params.contextId}/collaborations`, true));

    let view = () => {
      let state = store.getState();
      ReactDOM.render(<CollaborationsApp applicationState={state} actions={actions} />, document.getElementById('content'));
    };
    unsubscribe = store.subscribe(view);
    view();
  }

  function renderLaunchTool (ctx) {
    let view = () => {
      ReactDOM.render(<CollaborationsToolLaunch launchUrl={ctx.path.replace('/lti_collaborations', '')} />, document.getElementById('content'))
    }
    view()
  }

  /**
   * Middlewares
   */

  function parseQueryString (ctx, next) {
    ctx.query = qs.parse(ctx.querystring);
    next();
  }

  /**
   * Route Configuration
   */
  page('*', parseQueryString); // Middleware to parse querystring to object

  page('/:context(courses|groups)/:contextId/lti_collaborations', renderShowCollaborations);
  page.exit('/:context(courses|groups)/:contextId/lti_collaborations', (ctx, next) => {
    unsubscribe()
    next()
  })

  page('/:context(courses|groups)/:contextId/lti_collaborations/external_tools*', renderLaunchTool);

export default {
    start () {
      page.start();
    }
  };
