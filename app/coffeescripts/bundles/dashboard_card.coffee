require [
  'jquery'
  'underscore'
  'react'
  'jsx/dashboard_card/DashboardCardBox',
], ($, _, React, DashboardCardBox) ->
  element = React.createElement(DashboardCardBox, {
    courseCards: ENV.DASHBOARD_COURSES
  })
  dashboardContainer = document.getElementById('DashboardCard_Container')
  React.render(element, dashboardContainer)
