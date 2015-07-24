##
# add the [data-tooltip] attribute and title="<tooltip contents>" to anything you want to give a tooltip:
#
# usage: (see Styleguide)
#   <a data-tooltip title="pops up on top center">default</a>
#   <a data-tooltip="top" title="same as default">top</a>
#   <a data-tooltip="right" title="should be right center">right</a>
#   <a data-tooltip="bottom" title="should be bottom center">bottom</a>
#   <a data-tooltip="left" title="should be left center">left</a>
#   <a data-tooltip='{"track":true}' title="this toolstip will stay connected to mouse as it moves around">
#     tooltip that tracks mouse
#   </a>
#   <button data-tooltip title="any type of element can have a tooltip" class="btn">
#     button with tooltip
#   </button>

define [
  'underscore'
  'jquery'
  'str/htmlEscape'
  'jqueryui/tooltip'
], (_, $, htmlEscape) ->

  tooltipsToShortCirtuit = {}
  shortCircutTooltip = (target) ->
    tooltipsToShortCirtuit[target] || tooltipsToShortCirtuit[target[0]]

  tooltipUtils = {

    setPosition: (opts)->
      caret = ->
        if opts.tooltipClass?.match('popover')
          30
        else
          5
      collision = (if opts.force_position is "true" then "none" else "flipfit")
      positions =
        right:
          my: "left center"
          at: "right+#{caret()} center"
          collision: collision
        left:
          my: "right center"
          at: "left-#{caret()} center"
          collision: collision
        top:
          my: "center bottom"
          at: "center top-#{caret()}"
          collision: collision
        bottom:
          my: "center top"
          at: "center bottom+#{caret()}"
          collision: collision
      if opts.position of positions
        opts.position = positions[opts.position]

  }

  # create a custom widget that inherits from the default jQuery UI
  # tooltip but extends the open method with a setTimeout wrapper so
  # that our browser can scroll to the tabbed focus element before
  # positioning the tooltip relative to window.
  do ($) ->
    $.widget "custom.timeoutTooltip", $.ui.tooltip,
      _open: ( event, target, content ) ->
        return null if shortCircutTooltip(target)

        # Converts arguments to an array
        args = Array.prototype.slice.call(arguments, 0)
        args.splice(2, 1, htmlEscape(content).toString())
        # if you move very fast, it's possible that
        # @timeout will be defined
        return if @timeout
        apply = @_superApply.bind(@, args)
        @timeout = setTimeout (=>
          # make sure close will be called
          delete @timeout
          # remove extra handlers we added, super will add them back
          @_off(target, "mouseleave focusout keyup")
          apply()
        ), 20
        # this is from the jquery ui tooltip _open
        # we need to bind events to trigger close so that the
        # timeout is cleared when we mouseout / or leave focus
        @_on( target, {
          mouseleave: "close"
          focusout: "close"
          keyup: ( event ) ->
            if ( event.keyCode == $.ui.keyCode.ESCAPE )
              fakeEvent = $.Event(event)
              fakeEvent.currentTarget = target[0]
              this.close( fakeEvent, true )
          }
        )

      close: (event) ->
        if @timeout
          clearTimeout(@timeout)
          delete @timeout
          return
        @_superApply(arguments)

  # you can provide a 'using' option to jqueryUI position (which gets called by jqueryui Tooltip to
  # position it on the screen), it will be passed the position cordinates and a feedback object which,
  # among other things, tells you where it positioned it relative to the target. we use it to add some
  # css classes that handle putting the pointer triangle (aka: caret) back to the trigger.
  using = ( position, feedback ) ->
    $( this )
      .css( position )
      .removeClass( "left right top bottom center middle vertical horizontal" )
      .addClass([

        # one of: "left", "right", "center"
        feedback.horizontal

        # one of "top", "bottom", "middle"
        feedback.vertical

        # if tooltip was positioned mostly above/below trigger then: "vertical"
        # else since the tooltip was positioned more to the left or right: "horizontal"
        feedback.important
      ].join(' '))

  $('body').on 'mouseenter focusin', '[data-tooltip]', (event) ->
    $this = $(this)
    opts = $this.data('tooltip')

    # allow specifying position by simply doing <a data-tooltip="left">
    # and allow shorthand top|bottom|left|right positions like <a data-tooltip='{"position":"left"}'>
    if opts in ['right', 'left', 'top', 'bottom']
      opts = position: opts
    opts ||= {}
    opts.position ||= 'top'
    tooltipUtils.setPosition(opts)
    if opts.collision
      opts.position.collision = opts.collision

    opts.position.using ||= using

    if $this.data('html-tooltip-title')
      opts.content = -> $.raw($(this).data('html-tooltip-title'))
      opts.items = '[data-html-tooltip-title]'

    if $this.data('tooltip-class')
        opts.tooltipClass = $this.data('tooltip-class')

    $this
      .removeAttr('data-tooltip')
      .timeoutTooltip(opts)
      .timeoutTooltip('open')
      .click -> $this.timeoutTooltip('close')

  restartTooltip = (event) ->
    tooltipsToShortCirtuit[event.target] = false

  stopTooltip = (event) ->
    tooltipsToShortCirtuit[event.target] = true

  $(this).bind("detachTooltip", stopTooltip);
  $(this).bind("reattachTooltip", restartTooltip);

  return tooltipUtils
