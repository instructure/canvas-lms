require [
  'jquery'
  'react'
  'jsx/external_apps/routes'
], ($, React, routes) ->
  alreadyRendered = false

  $('#account_settings_tabs, #course_details_tabs').on 'tabscreate tabsactivate', (event, ui) =>
    targetNode = document.getElementById('external_tools')
    selectedTab = ui.tab || ui.newTab
    tabId = $(selectedTab).find('a').attr('id')
    if tabId == 'tab-tools-link'
      React.renderComponent(routes, targetNode)
      alreadyRendered = true
    else if alreadyRendered
      React.unmountComponentAtNode(targetNode)
      alreadyRendered = false
