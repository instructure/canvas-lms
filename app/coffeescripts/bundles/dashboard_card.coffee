require [
  'jquery'
  'underscore'
  'react'
  'react-dom'
  'jsx/dashboard_card/DashboardCardBox',
  'jsx/dashboard_card/getDroppableDashboardCardBox',
], ($, _, React, ReactDOM, DashboardCardBox, getDroppableDashboardCardBox) ->

  component = if ENV.DASHBOARD_REORDERING_ENABLED then getDroppableDashboardCardBox() else DashboardCardBox

  element = React.createElement(component, {
    courseCards: ENV.DASHBOARD_COURSES,
    reorderingEnabled: ENV.DASHBOARD_REORDERING_ENABLED
  })

  dashboardContainer = document.getElementById('DashboardCard_Container')
  ReactDOM.render(element, dashboardContainer)
