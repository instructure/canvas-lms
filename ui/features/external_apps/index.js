/*
 * Copyright (C) 2014 - present Instructure, Inc.
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
import ReactDOM from 'react-dom'
import router from './react/router'
import ready from '@instructure/ready'

let alreadyRendered = false

function renderReactApps(tabId) {
  const targetNode = document.getElementById('external_tools')
  if (tabId === 'tab-tools-link') {
    router.start(targetNode)
    alreadyRendered = true
  } else if (alreadyRendered) {
    ReactDOM.unmountComponentAtNode(targetNode)
    alreadyRendered = false
    router.stop()
  }
}

ready(() => {
  const activeTabId = $('li.ui-state-active > a').prop('id')
  if (activeTabId) {
    renderReactApps(activeTabId)
  }

  $('#account_settings_tabs, #course_details_tabs').on('tabscreate tabsactivate', (event, ui) => {
    const selectedTab = ui.tab || ui.newTab
    const tabId = $(selectedTab).find('a').attr('id')
    renderReactApps(tabId)
  })
})
