define [
  'Backbone'
  'compiled/jquery/outerclick'
], ({View}) ->

  class PopoverMenuView extends View

    events:
      'click': 'cancelHide'
      'focusin': 'cancelHide'
      'focusout': 'hide'
      'outerclick': 'hide'
      'keyup': 'checkEsc'

    showBy: ($target, focus = false) ->
      @cancelHide()
      setTimeout => # IE needs this to happen async frd
        @render()
        @$el.insertAfter($target)
        @$el.show()
        @setElement @$el
        @$el.zIndex(1)
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

    hide: =>
      @hideTimeout = setTimeout =>
        @$el.detach()
      , 100

    checkEsc: (e) ->
      @hide() if e.keyCode is 27 # escape
