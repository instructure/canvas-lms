define ['jquery'], ($) ->
  return unless ENV.ping_url
  setInterval(->
    $.post(ENV.ping_url) if document.hidden == false
  , 1000*180)
