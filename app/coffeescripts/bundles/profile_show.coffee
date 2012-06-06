require [
  'jquery'
  'jquery.ajaxJSON'
], ($) ->
  $followBtn = $ '#follow_user'
  $followBtn.click ->
    url =  "/api/v1/users/#{ENV.USER_ID}/followers/self.json"
    $.ajaxJSON url, 'PUT', {}, (data) -> $followBtn.hide()
