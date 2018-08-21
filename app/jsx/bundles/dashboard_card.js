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
import {get} from 'axios'

let promiseToGetDashboardCards

const sessionStorageKey = `dashcards_for_user_${ENV && ENV.current_user_id}`

export default function loadCardDashboard () {
  const Box = ENV.DASHBOARD_REORDERING_ENABLED ? getDroppableDashboardCardBox() : DashboardCardBox
  const dashboardContainer = document.getElementById('DashboardCard_Container')

  function render(dashboardCards) {
    ReactDOM.render(
      <Box
        courseCards={dashboardCards}
        reorderingEnabled={ENV.DASHBOARD_REORDERING_ENABLED}
        hideColorOverlays={ENV.PREFERENCES.hide_dashcard_color_overlays}
      />, dashboardContainer
    )
  }

  // Cache the fetched dashcards in sessionStorage so we can render instantly next
  // time they come to their dashboard (while still fetching the most current data)
  const cachedCards = sessionStorage.getItem(sessionStorageKey)
  if (cachedCards) render(JSON.parse(cachedCards))

  if (!promiseToGetDashboardCards) {
    promiseToGetDashboardCards = get('/dashboard/dashboard_cards').then(({data}) => data)
    promiseToGetDashboardCards.then((dashboardCards) =>
      sessionStorage.setItem(sessionStorageKey, JSON.stringify(dashboardCards))
    )
  }
  promiseToGetDashboardCards.then(render)
}
