define [
  'jquery'
], ($) ->

  $.fn.toggleAccessibly = (visible) ->
    if visible
      this.show()
      this.attr('aria-expanded', 'true')
    else
      this.hide()
      this.attr('aria-expanded', 'false')
    this
