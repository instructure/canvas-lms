/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import DashboardCardBox from '../dashboard_card/DashboardCardBox'
import getDroppableDashboardCardBox from '../dashboard_card/getDroppableDashboardCardBox'

export default function loadCardDashboard () {
  const Box = ENV.DASHBOARD_REORDERING_ENABLED ? getDroppableDashboardCardBox() : DashboardCardBox

  const dashboardContainer = document.getElementById('DashboardCard_Container')

  ReactDOM.render(
    <Box
      courseCards={ENV.DASHBOARD_COURSES}
      reorderingEnabled={ENV.DASHBOARD_REORDERING_ENABLED}
      hideColorOverlays={ENV.PREFERENCES.hide_dashcard_color_overlays}
    />, dashboardContainer
  )
}
