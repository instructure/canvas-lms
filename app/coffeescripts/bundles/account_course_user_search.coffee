require [
  'jquery'
  'react'
   "jsx/account_course_user_search/index"
], ($, React, App) ->
  React.render(
    React.createElement(
      App,
      {
        accountId: ENV.ACCOUNT_ID.toString(),
        permissions: ENV.PERMISSIONS
      }
    ),
    $("#content")[0]
  )
