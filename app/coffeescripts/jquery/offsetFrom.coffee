define ['jquery'], ($) ->

  # figure out where one element is relative to another (e.g. ancestor)
  #
  # useful when positioning menus and such when there are intermediate
  # positioned elements and/or you don't want it relative to the body (e.g.
  # menu inside a scrolling div)
  $.fn.offsetFrom = ($other) ->
    own = $(this).offset()
    other = $other.offset()
    {top: own.top - other.top, left: own.left - other.left}
