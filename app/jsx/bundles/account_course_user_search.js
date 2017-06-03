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
import App from 'jsx/account_course_user_search/index'
import router from 'jsx/account_course_user_search/router'
import configureStore from 'jsx/account_course_user_search/store/configureStore'
import initialState from 'jsx/account_course_user_search/store/initialState'

if (location.pathname.indexOf(ENV.BASE_PATH) === -1) {
  location.replace(ENV.BASE_PATH)
} else {
  initialState.tabList.basePath = ENV.BASE_PATH

  const content = document.getElementById('content')

  // Note. Only the UsersPane/Tab is using a redux store. The courses tab is
  // still using the old store model. That is why this might seem kind of weird.
  const store = configureStore(initialState)

  const options = {
    permissions: ENV.PERMISSIONS,
    accountId: ENV.ACCOUNT_ID.toString(),
    roles: Array.prototype.slice.call(ENV.COURSE_ROLES),
    addUserUrls: ENV.URLS,
    store
  }

  store.subscribe(() => {
    ReactDOM.render(<App {...options} />, content)
  })

  router.start(store)
}
