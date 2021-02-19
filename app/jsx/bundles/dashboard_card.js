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
import getDroppableDashboardCardBox from '../dashboard_card/getDroppableDashboardCardBox'
import axios from 'axios'
import {asJson, getPrefetchedXHR} from '@instructure/js-utils'

let promiseToGetDashboardCards

export function createDashboardCards(dashboardCards) {
  const Box = getDroppableDashboardCardBox()

  // Decide which dashboard to show based on role
  const current_roles = window.ENV.current_user_roles || []
  const isTeacher = current_roles.includes('teacher')

  return (
    <Box
      showSplitDashboardView={window.ENV?.FEATURES?.unpublished_courses && isTeacher}
      courseCards={dashboardCards}
      hideColorOverlays={ENV && ENV.PREFERENCES && ENV.PREFERENCES.hide_dashcard_color_overlays}
    />
  )
}

function renderIntoDOM(dashboardCards) {
  const dashboardContainer = document.getElementById('DashboardCard_Container')
  ReactDOM.render(createDashboardCards(dashboardCards), dashboardContainer)
}

export default function loadCardDashboard(renderFn = renderIntoDOM) {
  if (!promiseToGetDashboardCards) {
    let xhrHasReturned = false
    let sessionStorageTimeout
    const sessionStorageKey = `dashcards_for_user_${ENV && ENV.current_user_id}`
    const url = '/api/v1/dashboard/dashboard_cards'
    promiseToGetDashboardCards =
      asJson(getPrefetchedXHR(url)) || axios.get(url).then(({data}) => data)
    promiseToGetDashboardCards.then(() => (xhrHasReturned = true))

    // Because we use prefetch_xhr to prefetch this xhr request from our rails erb, there is a
    // chance that the XHR to get the latest dashcard data has already come back before we get
    // to this point. So if the XHR is ready, there's no need to render twice, just render
    // once with the newest data.
    // Otherwise, render with the cached stuff from session storage now, then render again
    // when the xhr comes back with the latest data.
    const promiseToGetCardsFromSessionStorage = new Promise(resolve => {
      sessionStorageTimeout = setTimeout(() => {
        const cachedCards = sessionStorage.getItem(sessionStorageKey)
        if (cachedCards) resolve(JSON.parse(cachedCards))
      }, 1)
    })
    Promise.race([promiseToGetDashboardCards, promiseToGetCardsFromSessionStorage]).then(
      dashboardCards => {
        clearTimeout(sessionStorageTimeout)
        renderFn(dashboardCards)
        if (!xhrHasReturned) promiseToGetDashboardCards.then(renderFn)
      }
    )

    // Cache the fetched dashcards in sessionStorage so we can render instantly next
    // time they come to their dashboard (while still fetching the most current data)
    promiseToGetDashboardCards.then(dashboardCards =>
      sessionStorage.setItem(sessionStorageKey, JSON.stringify(dashboardCards))
    )
  } else {
    promiseToGetDashboardCards.then(renderFn)
  }
}
