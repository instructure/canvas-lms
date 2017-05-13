import React from 'react'
import ReactDOM from 'react-dom'
import DashboardCardBox from 'jsx/dashboard_card/DashboardCardBox'
import getDroppableDashboardCardBox from 'jsx/dashboard_card/getDroppableDashboardCardBox'

const Box = ENV.DASHBOARD_REORDERING_ENABLED ? getDroppableDashboardCardBox() : DashboardCardBox

const dashboardContainer = document.getElementById('DashboardCard_Container')
ReactDOM.render(
  <Box
    courseCards={ENV.DASHBOARD_COURSES}
    reorderingEnabled={ENV.DASHBOARD_REORDERING_ENABLED}
    hideColorOverlays={ENV.PREFERENCES.hide_dashcard_color_overlays}
  />, dashboardContainer
)
