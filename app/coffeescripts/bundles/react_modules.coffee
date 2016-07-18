require [
  'jquery'
  'jsx/modules/reactModules'
], ($, reactModules) ->
  reactModules.render($('#content')[0])
