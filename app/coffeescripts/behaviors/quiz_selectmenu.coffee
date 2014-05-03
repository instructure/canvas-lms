define [
  'jquery'
], ($) ->

  # disable mousewheel in IE select menus to prevent accidental answer change
  $('.question select').bind "mousewheel", (event) -> event.preventDefault()
