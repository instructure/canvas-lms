define ['jquery'], ($) ->
  $unread = $('#identity .unread-messages-count')
  update = ->
    return unless document.hidden == false
    $.get('/api/v1/conversations/unread_count').done (response) ->
      $unread.text(response.unread_count)
      $unread.toggle(response.unread_count > 0)
  setInterval(update, 1000*30)
  update
