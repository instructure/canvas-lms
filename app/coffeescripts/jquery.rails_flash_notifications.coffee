# does Rails-style flash message/error boxes that drop down from the top of the screen
define [
  'i18n!shared.flash_notices'
  'jquery'
  'underscore'
  'compiled/fn/preventDefault'
  'str/htmlEscape'
  'jqueryui/effects/drop'
  'vendor/jquery.cookie'
], (I18n, $, _, preventDefault, htmlEscape) ->
  $holder = []
  $screenreader_holder = []

  initFlashContainer = ->
    $holder = $("#flash_message_holder")
    return if $holder.length == 0 # not defined yet; call $.initFlashContainer later
    $screenreader_holder = $("#flash_screenreader_holder")
    $holder.on 'click', '.close_link', preventDefault(->)
    $holder.on 'click', 'li', ->
      $this = $(this)
      return if $this.hasClass('no_close')
      $.cookie('unsupported_browser_dismissed', '1') if $this.hasClass('unsupported_browser')
      $this.stop(true, true).remove()
  initFlashContainer() # look for the container on script load

  escapeContent = (content) ->
    if content.hasOwnProperty('html') then content.html else htmlEscape(content)

  screenReaderFlashBox = (type, content) ->
    $screenreader_node = $("""
      <span>#{escapeContent(content)}</span>
    """)

    $screenreader_node.appendTo($screenreader_holder)
    # these aren't displayed, so removing them at a specified time is not critical
    window.setTimeout((-> $screenreader_node.remove()), 20000)

  flashBox = (type, content, timeout, cssOptions = {}) ->
    $node = $("""
      <li class="ic-flash-#{type}">
        <i></i>
        #{escapeContent(content)}
        <a href="#" class="close_link icon-end">#{I18n.t("close", "Close")}</a>
      </li>
    """)

    $node.appendTo($holder).
      css(_.extend(zIndex: 1, cssOptions)).
      show('drop', direction: "up", 'fast', -> $(this).css('z-index', 2)).
      delay(timeout || 7000).
      animate({'z-index': 1}, 0).
      fadeOut('slow', -> $(this).slideUp('fast', -> $(this).remove()))

    setTimeout((-> screenReaderFlashBox(type, content)), 100)

  # Pops up a small notification box at the top of the screen.
  $.flashMessage = (content, timeout = 3000) ->
    flashBox("success", content, timeout)

  # Pops up a small error box at the top of the screen.
  $.flashError = (content, timeout) ->
    flashBox("error", content, timeout)

  # Pops up a small warning box at the top of the screen.
  $.flashWarning = (content, timeout = 3000) ->
    flashBox("warning", content, timeout)

  $.screenReaderFlashMessage = (content) ->
    screenReaderFlashBox('success', content)

  $.screenReaderFlashError = (content) ->
    screenReaderFlashBox('error', content)

  # This is for when you want to clear the flash message content prior to
  # updating it with new content.  Makes it so the SR only reads this one
  # message.
  $.screenReaderFlashMessageExclusive = (content) ->
    $screenreader_holder.html("""
      <span>#{escapeContent(content)}</span>
    """)

  $.initFlashContainer = ->
    initFlashContainer()

  renderServerNotifications = ->
    if ENV.notices?
      for notice in ENV.notices
        flashBox(notice.type, notice.content)

  $ ->
    setTimeout(renderServerNotifications, 500)

