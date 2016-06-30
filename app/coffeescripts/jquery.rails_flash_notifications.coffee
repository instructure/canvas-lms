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

  ###
  xsslint safeString.function escapeContent
  ###
  escapeContent = (content) ->
    if content.hasOwnProperty('html') then content.html else htmlEscape(content)

  screenReaderFlashBox = (type, content) ->
    # nothing to do here if $screenreader_holder is not yet defined
    if $screenreader_holder.length > 0
      existing_nodes = $screenreader_holder.find('span')
      if existing_nodes.length > 0 && content.string
        message_text = content.string
        matching_node = _.find existing_nodes, (node) ->
                          $(node).text() == message_text
        if matching_node
          # need to remove and re-add error for accessibility, and to ensure
          # duplicate errors/messages do not pile up
          $(matching_node).remove()

    $screenreader_node = $("""
        <span>#{escapeContent(content)}</span>
      """)
    $screenreader_node.appendTo($screenreader_holder)
    # We are removing all the attributes and readding them due to Jaws inability
    # to communicate with IE.  If we were to just remove the element out right
    # NVDA would interrupt itself, however if we were to hide element Jaws will
    # read the element multiple times.
    window.setTimeout((->
      $screenreader_node.parent().each(->
        attributes = $.extend(true, {}, this.attributes);
        i = attributes.length;
        while( i-- )
          this.removeAttributeNode(attributes[i])

        $screenreader_node.remove()
        parentNode = this
        Array.prototype.forEach.call(attributes,(attribute) ->
          $(parentNode).attr(attribute.name, attribute.value))
        )
      ), 7000)

  flashBox = (type, content, timeout, cssOptions = {}) ->
    if type is "success"
      icon = "check"
    else if type is "warning" || type is "error"
      icon = "warning"
    else
      icon = "info"
    $node = $("""
      <li class="ic-flash-#{htmlEscape(type)}">
        <div class="ic-flash__icon" aria-hidden="true">
          <i class="icon-#{htmlEscape(icon)}"></i>
        </div>
        #{escapeContent(content)}
        <button type="button" class="Button Button--icon-action close_link">
          <span class="screenreader-only">
            #{htmlEscape I18n.t("close", "Close")}
          </span>
          <i class="icon-x" aria-hidden="true"></i>
        </button>
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
    # nothing to do here if $screenreader_holder is not yet defined
    if $screenreader_holder.length > 0
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

