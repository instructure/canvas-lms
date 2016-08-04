# does Rails-style flash message/error boxes that drop down from the top of the screen
define [
  'jquery'
  'underscore'
  'compiled/fn/preventDefault'
  'str/htmlEscape'
  'jsx/railsFlashNotificationsHelper'
  'jqueryui/effects/drop'
  'vendor/jquery.cookie'
], ($, _, preventDefault, htmlEscape, NotificationsHelper) ->

  helper = new NotificationsHelper

  initFlashContainer = ->
    helper.initHolder()
    helper.initScreenreaderHolder()
  initFlashContainer()

  # Pops up a small notification box at the top of the screen.
  $.flashMessage = (content, timeout = 3000) ->
    helper.createNode("success", content, timeout)
    createScreenreaderNodeWithDelay(content)

  # Pops up a small error box at the top of the screen.
  $.flashError = (content, timeout) ->
    helper.createNode("error", content, timeout)
    createScreenreaderNodeWithDelay(content)

  # Pops up a small warning box at the top of the screen.
  $.flashWarning = (content, timeout = 3000) ->
    helper.createNode("warning", content, timeout)
    createScreenreaderNodeWithDelay(content)

  $.screenReaderFlashMessage = (content) ->
    helper.createScreenreaderNode(content, false)

  $.screenReaderFlashError = (content) ->
    helper.createScreenreaderNode(content, false)

  # This is for when you want to clear the flash message content prior to
  # updating it with new content.  Makes it so the SR only reads this one
  # message.
  $.screenReaderFlashMessageExclusive = (content) ->
    helper.createScreenreaderNodeExclusive(content)

  $.initFlashContainer = ->
    initFlashContainer()

  renderServerNotifications = ->
    if ENV.notices?
      for notice in ENV.notices
        helper.createNode(notice.type, notice.content)
        createScreenreaderNodeWithDelay(notice.content)

  createScreenreaderNodeWithDelay = (content) ->
    setTimeout( ->
      helper.createScreenreaderNode(content)
    , 100)

  $ ->
    setTimeout(renderServerNotifications, 500)

