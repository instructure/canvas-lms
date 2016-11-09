require [
  'jquery'
  'underscore'
  'react'
  'react-dom'
  'jsx/dashboard_card/DashboardCardBox',
  'jsx/dashboard_card/getDroppableDashboardCardBox',
  'jsx/context_cards/StudentContextTray',
  'jsx/context_cards/StudentCardStore'
], ($, _, React, ReactDOM, DashboardCardBox, getDroppableDashboardCardBox, StudentContextTray, StudentCardStore) ->

  component = if ENV.DASHBOARD_REORDERING_ENABLED then getDroppableDashboardCardBox() else DashboardCardBox

  element = React.createElement(component, {
    courseCards: ENV.DASHBOARD_COURSES,
    reorderingEnabled: ENV.DASHBOARD_REORDERING_ENABLED
  })

  dashboardContainer = document.getElementById('DashboardCard_Container')
  ReactDOM.render(element, dashboardContainer)

  if ENV.PREFERENCES.tray_course_id && ENV.PREFERENCES.tray_user_id && ENV.PREFERENCES.STUDENT_CONTEXT_CARDS_ENABLED
    store = new StudentCardStore(
      ENV.PREFERENCES.tray_user_id, ENV.PREFERENCES.tray_course_id
    )

    element = React.createElement(StudentContextTray, {
      courseId: ENV.PREFERENCES.tray_course_id,
      isOpen: true,
      store: store,
      studentId: ENV.PREFERENCES.tray_user_id
    })
    studentContextTrayContainer = document.getElementById('StudentContextTray__Container')
    ReactDOM.render(element, studentContextTrayContainer)

