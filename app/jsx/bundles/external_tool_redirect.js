import $ from 'jquery'
import RedirectReturnContainer from 'compiled/external_tools/RedirectReturnContainer'

$(document).ready(() => {
  window.external_tool_redirect = {ready () {}}
  const container = new RedirectReturnContainer()
  container.attachLtiEvents()
})
