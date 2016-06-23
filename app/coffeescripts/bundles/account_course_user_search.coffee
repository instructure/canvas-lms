require [
  'jquery'
  'react'
  'jsx/account_course_user_search/index'
  'jsx/account_course_user_search/store/configureStore'
  'jsx/account_course_user_search/store/initialState'
], ($, React, App, configureStore, initialState) ->
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

  React.render( AccountCourseUserSearchApp(options), $("#content")[0] )
