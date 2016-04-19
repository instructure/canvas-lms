require [
  'react'
  'jsx/account_course_user_search/index'
  'jsx/account_course_user_search/router'
  'jsx/account_course_user_search/store/configureStore'
  'jsx/account_course_user_search/store/initialState'
], (React, App, router, configureStore, initialState) ->

  if (location.pathname.indexOf(ENV.BASE_PATH) == -1)
    return location.replace(ENV.BASE_PATH);

  initialState.tabList.basePath = ENV.BASE_PATH

  content = document.getElementById('content')
  AccountCourseUserSearchApp = React.createFactory App

  # Note. Only the UsersPane/Tab is using a redux store. The courses tab is
  # still using the old store model. That is why this might seem kind of weird.
  store = configureStore(initialState);

  options =
    permissions: ENV.PERMISSIONS,
    accountId: ENV.ACCOUNT_ID.toString()
    roles: ENV.ALL_ROLES
    addUserUrls: ENV.URLS
    store: store

  store.subscribe(
    -> React.render( AccountCourseUserSearchApp(options), content )
  )

  router.start(store)
