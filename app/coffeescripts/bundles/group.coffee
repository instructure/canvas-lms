require ['compiled/dashboardToggle'], (dashboardToggle) ->
  $('#breadcrumbs').prepend(dashboardToggle('enable'))
