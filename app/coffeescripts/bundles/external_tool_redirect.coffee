require [
  'jquery'
  'compiled/external_tools/RedirectReturnContainer'
], ($, RedirectReturnContainer) ->

  $(document).ready ->
    window.external_tool_redirect =
      ready: ->
    container = new RedirectReturnContainer
    container.attachLtiEvents()