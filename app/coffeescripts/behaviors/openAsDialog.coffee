define [
  'jquery'
  'compiled/fn/preventDefault'
  'jqueryui/dialog',
], ($, preventDefault) ->

  $.fn.openAsDialog = (options = {}) ->
    @click preventDefault (e) ->
      $link = $(e.target)

      options.width ?= 550
      options.height ?= 500
      options.title ?= $link.attr('title')
      options.resizable ?= false

      $dialog = $("<div>")
      $iframe = $('<iframe>', style: "position:absolute;top:0;left:0;border:none", src: $link.attr('href') + '?embedded=1&no_headers=1')
      $dialog.append $iframe

      $dialog.on "dialogopen", ->
        $container = $dialog.closest('.ui-dialog-content')
        $iframe.height $container.outerHeight()
        $iframe.width $container.outerWidth()
      $dialog.dialog options

  $ ->
    $('a[data-open-as-dialog]').openAsDialog()

  $
