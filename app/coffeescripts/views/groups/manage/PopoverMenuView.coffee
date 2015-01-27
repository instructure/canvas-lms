define [
  'jquery'
  'Backbone'
  'compiled/jquery/outerclick'
], ($, {View}) ->

  class PopoverMenuView extends View

    defaults:
      zIndex: 1

    events:
      'click': 'cancelHide'
      'focusin': 'cancelHide'
      'focusout': 'hidePopover'
      'outerclick': 'hidePopover'
      'keyup': 'checkEsc'

    hidePopover: ->
      @hide() #call the hide function without any arguments.

    showBy: ($target, focus = false) ->
      @cancelHide()
      setTimeout => # IE needs this to happen async frd
        @render()
        @attachElement($target)
        @$el.show()
        @setElement @$el
        @$el.zIndex(@options.zIndex)
        @setWidth?()
        @$el.position
          my: @my or 'left+6 top-47'
          at: @at or 'right center'
          of: $target
          collision: 'none'
          using: (coords) =>
            content = @$el.find '.popover-content'
            @$el.css top: coords.top, left: coords.left
            @setPopoverContentHeight(@$el, content, $('#content'))

        @focus?() if focus
        @trigger("open", { "target" : $target })
      , 20

    setPopoverContentHeight: (popover, content, parent) ->
      parentBound = parent.offset().top + parent.height()
      popoverOffset = popover.offset().top
      popoverHeader = popover.find('.popover-title').outerHeight()
      defaultHeight = parseInt content.css('maxHeight')
      newHeight = parentBound - popoverOffset - popoverHeader
      content.css maxHeight: Math.min(defaultHeight, newHeight)

    cancelHide: =>
      clearTimeout @hideTimeout

    hide: (escapePressed = false) =>
      @hideTimeout = setTimeout =>
        @$el.detach()
        @trigger("close", {"escapePressed": escapePressed})
      , 100

    checkEsc: (e) ->
      @hide(true) if e.keyCode is 27 # escape

    attachElement: ($target) ->
      @$el.insertAfter($target)
