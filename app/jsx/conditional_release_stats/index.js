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

import { bindActionCreators } from 'redux'
import App from './app'
import createStore from './create-store'
import { actions } from './actions'

  const CyoeStats = {
    init: (graphsRoot, detailsParent) => {
      const ENV = window.ENV
      if (graphsRoot != null &&
        ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED &&
        ENV.CONDITIONAL_RELEASE_ENV.rule != null)
      {
        const { assignment, jwt, stats_url } = ENV.CONDITIONAL_RELEASE_ENV

        const detailsRoot = document.createElement('div')
        detailsRoot.setAttribute('id', 'crs-details')
        detailsParent.appendChild(detailsRoot)

        assignment.submission_types = Array.isArray(assignment.submission_types) ? assignment.submission_types : [assignment.submission_types]
        const initState = {
          assignment,
          jwt,
          apiUrl: stats_url,
        }

        const store = createStore(initState)
        const boundActions = bindActionCreators(actions, store.dispatch)

        const app = new App(store, boundActions)

        app.renderGraphs(graphsRoot)
        app.renderDetails(detailsRoot)

        boundActions.loadInitialData()

        return app
      }
    },
  }

export default CyoeStats
