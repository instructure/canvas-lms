require [
  'jquery'
  'underscore'
  'react'
  'react-dom'
  'jsx/dashboard_card/DashboardCardBox',
], ($, _, React, ReactDOM, DashboardCardBox) ->
  element = React.createElement(DashboardCardBox, {
    courseCards: ENV.DASHBOARD_COURSES
  })
  dashboardContainer = document.getElementById('DashboardCard_Container')
  ReactDOM.render(element, dashboardContainer)
