define ['jquery'], ($) ->
  return unless ENV.ping_url
  interval = setInterval(->
    $.post(ENV.ping_url).fail((xhr) ->
      clearInterval(interval) if xhr.status == 401
    ) if document.hidden == false
  , 1000*180)
