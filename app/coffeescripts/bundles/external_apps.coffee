require [
  'jquery'
  'react'
  'react-dom'
  'jsx/external_apps/router'
], ($, React, ReactDOM, router) ->
  alreadyRendered = false

  render_react_apps = (tabId) ->
    targetNode = document.getElementById('external_tools')
    if tabId == 'tab-tools-link'
      router.start(targetNode)
      alreadyRendered = true
    else if alreadyRendered
      ReactDOM.unmountComponentAtNode(targetNode)
      alreadyRendered = false
      router.stop()

  activeTabId = $('li.ui-state-active > a').prop('id')
  render_react_apps(activeTabId) if activeTabId

  $('#account_settings_tabs, #course_details_tabs').on 'tabscreate tabsactivate', (event, ui) =>
    selectedTab = ui.tab || ui.newTab
    tabId = $(selectedTab).find('a').attr('id')
    render_react_apps(tabId)
