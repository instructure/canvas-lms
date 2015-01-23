require [
  'jquery'
  'react'
  'react-router'
  'jsx/external_apps/routes'
], ($, React, Router, routes) ->
  alreadyRendered = false

  $('#account_settings_tabs, #course_details_tabs').on 'tabscreate tabsactivate', (event, ui) =>
    targetNode = document.getElementById('external_tools')
    selectedTab = ui.tab || ui.newTab
    tabId = $(selectedTab).find('a').attr('id')
    if tabId == 'tab-tools-link'

      Router.run routes, Router.HistoryLocation, (Handler) ->
        React.render React.createElement(Handler, null), targetNode

      alreadyRendered = true
    else if alreadyRendered
      React.unmountComponentAtNode(targetNode)
      alreadyRendered = false
