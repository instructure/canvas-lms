require [
  'jquery'
  'vendor/jquery.tablesorter'
], ($) ->
  $(document).ready ->
    $.tablesorter.addParser(
      id: 'days_or_never'
      is: -> false
      format: (s) ->
        str = $.trim(s)
        val = parseInt(str, 10) || 0
        -1 * (if str == 'never' then Number.MAX_VALUE else val)
      type: 'number'
    )
    $.tablesorter.addParser(
      id: 'data-number'
      is: -> false
      format: (s, table, td) ->
        $(td).attr('data-number')
      type: 'number'
    )
    has_user_notes = $(".report").hasClass('has_user_notes')
    params = 
      headers:
        0: 
          sorter: 'data-number'
        1: 
          sorter: 'days_or_never'
    if has_user_notes
      params['headers'][2] = sorter: 'days_or_never'
    params['headers'][4 + (has_user_notes ? 1 : 0)] = 
      sorter: 'data-number'
    params['headers'][5 + (has_user_notes ? 1 : 0)] = 
      sorter: false

    $(".report").tablesorter(params)

