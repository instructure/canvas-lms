define [
  'jquery'
], ($) ->
  
  # possible values for position are 'center' and 'after', see g_util_misc.scss
  # passign a position is optional and if ommited will use 'center'
  $.fn.indicateLoading = (position, deferred) ->
    unless deferred?
      deferred = position
      position = 'center'
    @each ->
      $this = $(this).addClass 'loading ' + position
      $.when(deferred).done ->
        $this.removeClass 'loading ' + position