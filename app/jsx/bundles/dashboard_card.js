import React from 'react'
import ReactDOM from 'react-dom'
import DashboardCardBox from 'jsx/dashboard_card/DashboardCardBox'
import getDroppableDashboardCardBox from 'jsx/dashboard_card/getDroppableDashboardCardBox'

const component = ENV.DASHBOARD_REORDERING_ENABLED ? getDroppableDashboardCardBox() : DashboardCardBox

const element = React.createElement(component, {
  courseCards: ENV.DASHBOARD_COURSES,
  reorderingEnabled: ENV.DASHBOARD_REORDERING_ENABLED
})

const dashboardContainer = document.getElementById('DashboardCard_Container')
ReactDOM.render(element, dashboardContainer)
