define [
  'jquery'
], ($) ->

  fireKeyclick = (e) ->
    kce = $.Event('keyclick')
    $(e.target).trigger(kce)
    e.preventDefault() if kce.isDefaultPrevented()
    e.stopPropagation() if kce.isPropogationStopped()

  keydownHandler = (e) ->
    switch e.which
      when 13
        fireKeyclick(e)
      when 32
        # prevent scrolling when the spacebar is pressed on a "button"
        e.preventDefault()

  keyupHandler = (e) ->
    switch e.which
      when 32
        fireKeyclick(e)

  $.fn.activate_keyclick = (selector=null) ->
    this.on 'keydown', selector, keydownHandler
    this.on 'keyup', selector, keyupHandler

  $(document).activate_keyclick('[role=button], [role=checkbox]')
