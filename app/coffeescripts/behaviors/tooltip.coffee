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
  'jqueryui/tooltip'
], (_, $) ->

  CARET_SIZE = 5

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

  positions =
    right:
      my: "left center"
      at: "right+#{CARET_SIZE} center"
      collision: 'flipfit flipfit'
    left:
      my: "right center"
      at: "left-#{CARET_SIZE} center"
      collision: 'flipfit flipfit'
    top:
      my: "center bottom"
      at: "center top-#{CARET_SIZE}"
      collision: 'flipfit flipfit'

    bottom:
      my: "center top"
      at: "center bottom+#{CARET_SIZE}"
      collision: 'flipfit flipfit'

  $('body').on 'mouseover', '[data-tooltip]', (event) ->
    $this = $(this)
    opts = $this.data('tooltip')

    # allow specifying position by simply doing <a data-tooltip="left">
    # and allow shorthand top|bottom|left|right positions like <a data-tooltip='{"position":"left"}'>
    if opts of positions
      opts = position: opts
    opts ||= {}
    opts.position ||= 'top'
    if opts.position of positions
      opts.position = positions[opts.position]

    opts.position.using ||= using

    $this
      .removeAttr('data-tooltip')
      .tooltip(opts)
      .tooltip('open')
      .click -> $this.tooltip('close')
