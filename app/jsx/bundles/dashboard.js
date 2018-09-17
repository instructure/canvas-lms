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

import $ from 'jquery'
import 'compiled/jquery.rails_flash_notifications'
import 'jquery.disableWhileLoading'
import React from 'react'
import ReactDOM from 'react-dom'
import DashboardHeader from '../dashboard/DashboardHeader'

const dashboardHeaderContainer = document.getElementById('dashboard_header_container');
if (dashboardHeaderContainer) {
  const dashboard_view = ENV.PREFERENCES.dashboard_view;

  ReactDOM.render(
    <DashboardHeader
      dashboard_view={dashboard_view}
      planner_enabled={ENV.STUDENT_PLANNER_ENABLED}
      flashError={$.flashError}
      flashMessage={$.flashMessage}
      screenReaderFlashMessage={$.screenReaderFlashMessage}
      env={window.ENV}
    />,
    dashboardHeaderContainer
  )
} else {
  // if we are on the root dashboard page, then we conditinally load the
  // stream items and initialize the backbone view in DashboardHeader
  // but on a course dashboard, erb html is there as part of the page load and
  // we can initialize the backbone view immediately
  import('../views/DashboardView').then(DashboardView => new DashboardView())
}
