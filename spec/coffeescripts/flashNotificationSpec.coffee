require [
  'jquery'
  'compiled/jquery.rails_flash_notifications'
], ($) ->
  module 'FlashNotifications',
    setup: ->
      @fixture = $('<div id="flash_message_holder"/><div id="flash_screenreader_holder"/>').appendTo('#fixtures')
      $.initFlashContainer()
    teardown: ->
      @fixture.remove()

  test 'text notification', ->
    $.flashMessage('here is a thing')
    ok $('#flash_message_holder .ic-flash-success').text().match(/here is a thing/)

  test 'html sanitization', ->
    $.flashWarning('<script>evil()</script>')
    ok $('#flash_message_holder .ic-flash-warning').html().match(/&lt;script&gt;/)

  test 'html messages', ->
    $.flashError({html: '<div class="blah">test</div>'})
    ok $('#flash_message_holder .ic-flash-error div.blah').text().match(/test/)

  test 'screenreader message', ->
    $.screenReaderFlashMessage('<script>evil()</script>')
    ok $('#flash_screenreader_holder span').html().match(/&lt;script&gt;/)