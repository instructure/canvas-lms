define ['jquery'], ($) ->
  # depends on the scrollable ancestor being the first positioned
  # ancestor. if it's not, it won't work
  $.fn.scrollIntoView = (options = {}) ->
    $container = options.container or @offsetParent()
    containerTop = $container.scrollTop()
    containerBottom = containerTop + $container.height()
    elemTop = this[0].offsetTop
    elemBottom = elemTop + $(this[0]).outerHeight()
    if options.ignore?.border
      elemTop += parseInt($(this[0]).css('border-top-width').replace('px', ''))
      elemBottom -= parseInt($(this[0]).css('border-bottom-width').replace('px', ''))
    if elemTop < containerTop or options.toTop
      $container.scrollTop(elemTop)
    else if elemBottom > containerBottom
      $container.scrollTop(elemBottom - $container.height())

