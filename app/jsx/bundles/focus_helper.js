require [
  'jquery'
  'compiled/util/deparam'
], ($, deparam) ->
  $(document).ready ->
    params = deparam()
    if params.focus
      el = $("##{params.focus}")
      if el
        el.select() if el.attr('type') == 'text'
        el.focus()