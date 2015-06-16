require [
  'jquery'
  'react'
  'react-router'
  'jsx/external_apps/routes'
], ($, React, Router, routes) ->
  alreadyRendered = false

  render_react_apps = (tabId) ->
    targetNode = document.getElementById('external_tools')
    if tabId == 'tab-tools-link'
      Router.run routes, Router.HistoryLocation, (Handler) ->
        React.render React.createElement(Handler, null), targetNode

      alreadyRendered = true
    else if alreadyRendered
      React.unmountComponentAtNode(targetNode)
      alreadyRendered = false

  activeTabId = $('li.ui-state-active > a').prop('id')
  render_react_apps(activeTabId) if activeTabId

  $('#account_settings_tabs, #course_details_tabs').on 'tabscreate tabsactivate', (event, ui) =>
    selectedTab = ui.tab || ui.newTab
    tabId = $(selectedTab).find('a').attr('id')
    render_react_apps(tabId)
