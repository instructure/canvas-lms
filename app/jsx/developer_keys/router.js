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

import React from 'react'
import ReactDOM from 'react-dom'
import page from 'page'
import qs from 'qs'
import DeveloperKeysApp from './DeveloperKeysApp'
import actions from './actions/developerKeysActions'
import store from './store/store'

/**
 * Route Handlers
 */
// ctx is context
function renderShowDeveloperKeys (ctx) {
  store.dispatch(actions.getDeveloperKeys(`/api/v1/accounts/${ctx.params.contextId}/developer_keys`, true));

  const view = () => {
    const state = store.getState();
    ReactDOM.render(
      <DeveloperKeysApp
        applicationState={state}
        actions={actions}
        store={store}
        ctx={ctx}
      />,
      document.getElementById('reactContent'));
  };
  // returns A function that unsubscribes the change listener.
  store.subscribe(view);

  // renders the page
  view();
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

page('/accounts/:contextId/developer_keys', renderShowDeveloperKeys);

// export default for a module
// when we import router.js, this is what we get by default
export default {
  start () {
    page.start();
  }
};

