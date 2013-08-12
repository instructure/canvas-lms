define [
  'jquery'
], ($) ->

  # Redirects click events from one element to another
  #
  # This allows, for example, to make a row clickable but while
  # preserving some built-in functionality provided by the browser
  # (e.g. ctrl+click to open in a new tab)
  #
  # By default, the element with the click redirected is styled with
  # cursor: pointer, this can be overwritten by providing a css
  # option with the desired css. If css is set to false, no styling
  # is performed.
  #
  # To prevent redirecting a particular click event, you must call
  # preventDefault on the event before redirectClickTo receives the
  # event. Click events on the target are allowed to pass through.
  $.fn.redirectClickTo = (target, options={}) ->
    # get the raw dom element
    target = $(target).get(0)
    return unless target

    # style the element to indicate to the user that it is clickable
    css = options.css || {cursor:'pointer'} unless options.css == false
    this.css(css) if css

    this.off '.redirectClickTo'
    this.on 'click.redirectClickTo', (event) ->
      # ignore events for the target (prevents infinite recursion)
      ignoreEvent = event.target == target
      # also ignore events that are marked to prevent default
      ignoreEvent = ignoreEvent || event.isDefaultPrevented()

      unless ignoreEvent
        # stop processing this event (it'll be re-dispatched to the target anyway)
        event.stopPropagation()
        event.preventDefault()

        if document.createEvent
          # clone the original event and re-dispatch on the target
          # note: cloning from the originalEvent to prevent jquery muckings
          oevent = event.originalEvent

          e = document.createEvent('MouseEvents')
          e.initMouseEvent(
            oevent.type
            true
            true
            window
            0
            oevent.screenX
            oevent.screenY
            oevent.clientX
            oevent.clientY
            oevent.ctrlKey
            oevent.altKey
            oevent.shiftKey
            oevent.metaKey
            oevent.button
            oevent.relatedTarget
          )
          target.dispatchEvent(e)
        else if target.click
          # fallback in case document.createEvent is missing
          # note: I do not know of any supported browsers needing
          #       this, it's more of a just-in-case
          target.click()
