# does Rails-style flash message/error boxes that drop down from the top of the screen
define [
  'i18n!shared.flash_notices'
  'underscore'
  'compiled/fn/preventDefault'
  'jqueryui/effects/drop'
  'vendor/jquery.cookie'
], (I18n, _, preventDefault) ->

  $buffer = $("#flash_message_buffer")
  $holder = $("#flash_message_holder")
  $holder.on 'click', '.close_link', preventDefault
  $holder.on 'click', 'li', ->
    $this = $(this)
    return if $this.hasClass('no_close')
    $.cookie('unsupported_browser_dismissed', '1') if $this.hasClass('unsupported_browser')
    $this.stop(true, true).remove()
    if (bufferIndex = $this.data('buffer-index'))?
      $buffer.find("[data-buffer-index=#{bufferIndex}]").remove()

  flashBox = (type, content, timeout, cssOptions = {}) ->
    $node = $("""
      <li class="ic-flash-#{type}" role="alert">
        <i></i>
        #{content}
        <a href="#" class="close_link icon-end">#{I18n.t("close", "Close")}</a>
      </li>
    """)

    $node.appendTo($holder).
      css(_.extend(zIndex: 1, cssOptions)).
      show('drop', direction: "up", 'fast', -> $(this).css('z-index', 2)).
      delay(timeout || 7000).
      animate({'z-index': 1}, 0).
      fadeOut('slow', -> $(this).slideUp('fast', -> $(this).remove()))
  
  # Pops up a small notification box at the top of the screen.
  $.flashMessage = (content, timeout = 3000) ->
    flashBox("success", content, timeout)

  # Pops up a small error box at the top of the screen.
  $.flashError = (content, timeout) ->
    flashBox("error", content, timeout)

  $.screenReaderFlashMessage = (content, timeout = 3000) ->
    flashBox('success', content, timeout, position: 'absolute', left: -10000)

  $.screenReaderFlashError = (content, timeout = 3000) ->
    flashBox('error', content, timeout, position: 'absolute', left: -10000)
