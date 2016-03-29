define [
  'jquery'
  'jquery.ajaxJSON'
], ($) ->
  toggle: (button) ->
    data = $(button).data.bind($(button))
    $.ajaxJSON(
      (data 'url'),
      if data 'isChecked' then 'DELETE' else 'PUT',
      {},
      ->
        data 'isChecked', !(data 'isChecked')
        $(button).toggleClass 'btn-success'
        $('i', button).toggleClass 'icon-empty icon-complete'
        $('.mark-done-labels span', button).toggleClass 'visible'
    )
