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
