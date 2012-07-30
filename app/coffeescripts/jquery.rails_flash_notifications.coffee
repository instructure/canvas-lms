# does Rails-style flash message/error boxes that drop down from the top of the screen
define [
  'i18n!shared.flash_notices'
  'underscore'
  'compiled/fn/preventDefault'
  'jqueryui/effects/drop'
], (I18n, _, preventDefault) ->

  $buffer = $("#flash_message_buffer")
  $holder = $("#flash_message_holder")
  $holder.on 'click', '.close_link', preventDefault
  $holder.on 'click', 'li', ->
    $this = $(this)
    return if $this.hasClass('no_close')
    $this.stop(true, true).remove()
    if $this.hasClass('static_message')
      $buffer.height _.reduce($holder.find('.static_message'),
        (s, n) -> s + $(n).outerHeight()
      , 0)

  flashBox = (type, content, timeout) ->
    $node = $("""
      <li class='ui-state-#{type}'>
        <i></i>
        #{content}
        <a href='#' class='close_link'>#{I18n.t("close", "Close")}</a>
      </li>
    """)

    $node.appendTo($holder).
      css('z-index', 1).
      show('drop', direction: "up", 'fast', -> $(this).css('z-index', 2)).
      delay(timeout || 7000).
      animate({'z-index': 1}, 0).
      fadeOut('slow', -> $(this).slideUp('fast', -> $(this).remove()))
  
  # Pops up a small notification box at the top of the screen.
  $.flashMessage = (content, timeout = 3000) ->
    flashBox("success", content, timeout)

  # Pops up a small error box at the top of the screen.
  $.flashError = (content, timeout) ->
    flashBox("error", content, timeout);

