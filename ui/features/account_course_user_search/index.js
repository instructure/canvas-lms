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

import $ from 'jquery'
import React from 'react'
import ReactDOM from 'react-dom'
import App from './react/index'
import router from './react/router'
import configureStore from './react/store/configureStore'
import initialState from './react/store/initialState'
import ready from '@instructure/ready'

// eg: '/accounts/xxx' for anything like '/accounts/xxx/whatever`
initialState.tabList.basePath = window.location.pathname.match(/.*accounts\/[^/]*/)[0]

// Note. Only the UsersPane/Tab is using a redux store. The courses tab is
// still using the old store model. That is why this might seem kind of weird.
const store = configureStore(initialState)

const props = {
  permissions: ENV.PERMISSIONS,
  rootAccountId: ENV.ROOT_ACCOUNT_ID.toString(),
  accountId: ENV.ACCOUNT_ID.toString(),
  roles: Array.prototype.slice.call(ENV.COURSE_ROLES),
  addUserUrls: ENV.URLS,
  store,
}

// this is where we take care of the 3 things we need to do outside of the
// happy React/redux  declarative/vDOM blessed path. It's so when we click
// either the "Courses" or "People" tabs on the left, it highlights the right
// tab and updates the crumb and document title
const originalDocumentTitle = document.title
function updateDocumentTitleBreadcrumbAndActiveTab(activeTab) {
  // give the correct left nav item an active class
  $('#section-tabs .section a').each(function () {
    const $tab = $(this)
    $tab[$tab.hasClass(activeTab.button_class) ? 'addClass' : 'removeClass']('active')
  })

  // update the page title
  document.title = `${activeTab.title}: ${originalDocumentTitle}`

  // toggle the breadcrumb between "Corses" and "People"
  $('#breadcrumbs a:last span').text(activeTab.title)
}
ready(() => {
  const content = document.getElementById('content')
  store.subscribe(() => {
    const tabState = store.getState().tabList
    const selectedTab = tabState.tabs[tabState.selected]
    updateDocumentTitleBreadcrumbAndActiveTab(selectedTab)

    ReactDOM.render(<App {...props} />, content)
  })

  router.start(store)
})
