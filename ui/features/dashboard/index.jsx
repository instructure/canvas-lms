/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

import ready from '@instructure/ready'

import '@canvas/rails-flash-notifications'
import '@canvas/jquery/jquery.disableWhileLoading'
// eslint-disable-next-line import/no-named-as-default
import DashboardHeader from './react/DashboardHeader'

ready(() => {
  const dashboardHeaderContainer = document.getElementById('dashboard_header_container')
  if (dashboardHeaderContainer) {
    const dashboard_view = ENV.PREFERENCES.dashboard_view

    ReactDOM.render(
      <DashboardHeader
        dashboard_view={dashboard_view}
        allowElementaryDashboard={!!ENV.ALLOW_ELEMENTARY_DASHBOARD}
        isElementaryUser={!!ENV.K5_USER}
        planner_enabled={ENV.STUDENT_PLANNER_ENABLED}
        flashError={$.flashError}
        flashMessage={$.flashMessage}
        screenReaderFlashMessage={$.screenReaderFlashMessage}
        env={window.ENV}
        {...$(dashboardHeaderContainer).data('props')}
      />,
      dashboardHeaderContainer
    )
  } else {
    // if we are on the root dashboard page, then we conditinally load the
    // stream items and initialize the backbone view in DashboardHeader
    // but on a course dashboard, erb html is there as part of the page load and
    // we can initialize the backbone view immediately
    import('./backbone/views/DashboardView').then(({default: DashboardView}) => new DashboardView())
  }
})
