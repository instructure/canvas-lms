define ['jquery'], ($) ->
  ->
    $('.vdd_tooltip_link').tooltip
      position: {my: 'center bottom', at: 'center top-10', collision: 'fit fit'},
      tooltipClass: 'center bottom vertical',
      content: ->
        $($(this).data('tooltipSelector')).html()