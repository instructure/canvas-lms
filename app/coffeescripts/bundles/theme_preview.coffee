require [
  'jquery'
  'underscore'
  'jqueryui/accordion'
  'jqueryui/tabs'
  'jqueryui/button'
], ($, _) ->

  do ->
    $("#theme-preview-tabs").tabs()
    $("#theme-preview-accordion").accordion({header: "h3"})
