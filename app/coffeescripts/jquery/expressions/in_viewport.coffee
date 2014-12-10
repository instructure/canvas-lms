define (require) ->
  $ = require('jquery')
  $window = $(window)

  # @method $.fn.is(':in_viewport')
  #
  # Checks whether an element is visible in the current window's scroll
  # boundaries.
  #
  # An example of scrolling an element into view if it's not visible:
  #
  #     if (!$('#element').is(':in_viewport')) {
  #       $('#element').scrollIntoView();
  #     }
  #
  # Or, using $.fn.filter:
  #
  #     // iterate over all questions that are currently visible to the student:
  #     $('.question').filter(':in_viewport').each(function() {
  #     });
  inViewport = (el)->
    $el = $(el)

    vpTop    = $window.scrollTop()
    vpBottom = vpTop + $window.height()
    elTop    = $el.offset().top
    elBottom = elTop + $el.height()

    return vpTop < elTop && vpBottom > elBottom

  $.extend($.expr[':'], {
    in_viewport: inViewport
  });

  inViewport
