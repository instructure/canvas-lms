import $ from 'jquery'
import React from 'react'
import ReactDOM from 'react-dom'
import router from 'jsx/external_apps/router'

let alreadyRendered = false

const render_react_apps = function (tabId) {
  const targetNode = document.getElementById('external_tools')
  if (tabId === 'tab-tools-link') {
    router.start(targetNode)
    alreadyRendered = true
  } else if (alreadyRendered) {
    ReactDOM.unmountComponentAtNode(targetNode)
    alreadyRendered = false
    router.stop()
  }
}

const activeTabId = $('li.ui-state-active > a').prop('id')
if (activeTabId) { render_react_apps(activeTabId) }

$('#account_settings_tabs, #course_details_tabs').on('tabscreate tabsactivate', (event, ui) => {
  const selectedTab = ui.tab || ui.newTab
  const tabId = $(selectedTab).find('a').attr('id')
  render_react_apps(tabId)
})

