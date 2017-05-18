#
# Copyright (C) 2012 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'jquery'
], ($) ->


  # you can provide a 'using' option to jqueryUI position
  # it will be passed the position cordinates and a feedback object which,
  # among other things, tells you where it positioned it relative to the target. we use it to add some
  # css classes that handle putting the pointer triangle (aka: caret) back to the trigger.
  using = ( position, feedback ) ->
    position.top = 0 if position.top < 0
    $( this )
      .css( position )
      .toggleClass('carat-bottom', feedback.vertical == 'bottom')



  idCounter = 0
  activePopovers = []

  class Popover
    constructor: (triggerEvent, @content, @options = {}) ->
      @trigger = $(triggerEvent.currentTarget)
      @triggerAction = triggerEvent.type
      @el = $(@content)
              .addClass('carat-bottom')
              .data('popover', this)
              .keydown (event) =>
                # if the user hits the escape key, reset the focus to what it was.
                if event.keyCode is $.ui.keyCode.ESCAPE
                  @hide()
                # If the user tabs or shift-tabs away, close.
                return unless event.keyCode is $.ui.keyCode.TAB
                tabbables = $ ":tabbable", @el
                index = $.inArray event.target, tabbables
                return if index == -1

                if event.shiftKey
                  @hide() if index == 0
                else
                  @hide() if index == tabbables.length-1

      @el.delegate '.popover_close', 'keyclick click', (event) =>
        event.preventDefault()
        @hide()

      @show(triggerEvent)

    show: (triggerEvent) ->
      # when the popover is open, we don't want SR users to be able to navigate to the flash messages
      $.screenReaderFlashMessageExclusive('')

      popoverToHide.hide() while popoverToHide = activePopovers.pop()
      activePopovers.push(this)
      id = "popover-#{idCounter++}"
      @trigger.attr
        "aria-expanded" : true
        "aria-controls" : id
      @previousTarget = triggerEvent.currentTarget

      @el
        .attr(
          'id' : id
        )
        .appendTo(document.body)
        .show()
      @position()
      unless triggerEvent.type == "mouseenter"
        @el.find(':tabbable').first().focus()
        setTimeout(
          () =>
            @el.find(':tabbable').first().focus()
          , 100
        )

      document.querySelector('#application').setAttribute('aria-hidden', 'true')

      # handle sticking the carat right above where you clicked on the button, bounded by the dialog
      @el.find(".ui-menu-carat").remove()
      additionalOffset = @options.manualOffset || 0
      differenceInOffset = @trigger.offset().left - @el.offset().left
      actualOffset = triggerEvent.pageX - @trigger.offset().left
      leftBound = Math.max(0, @trigger.width() / 2 - @el.width() / 2) + 20
      rightBound = @trigger.width() - leftBound
      caratOffset = Math.min(Math.max(leftBound, actualOffset), rightBound) + differenceInOffset + additionalOffset
      $('<span class="ui-menu-carat"><span /></span>').css('left', caratOffset).prependTo(@el)

      @positionInterval = setInterval @position, 200
      $(window).click @outsideClickHandler

    hide: ->
      # remove this from the activePopovers array
      for popover, index in activePopovers
        activePopovers.splice(index, 1) if this is popover

      @el.detach()
      @trigger.attr 'aria-expanded', false
      clearInterval @positionInterval
      $(window).unbind 'click', @outsideClickHandler
      @restoreFocus()

      if activePopovers.length == 0
        document.querySelector('#application').setAttribute('aria-hidden', 'false')

    ignoreOutsideClickSelector: '.ui-dialog'

    # uses a fat arrow so that it has a unique guid per-instance for jquery event unbinding
    outsideClickHandler: (event) =>
      unless $(event.target).closest(@el.add(@trigger).add(@ignoreOutsideClickSelector)).length
        @hide()

    position: =>
      @el.position
        my: 'center '+(if @options.verticalSide == 'bottom' then 'top' else 'bottom'),
        at: 'center '+(@options.verticalSide || 'top'),
        of: @trigger,
        offset: "0px #{@offsetPx()}px",
        within: 'body',
        collision: 'flipfit '+(if @options.verticalSide then 'none' else 'flipfit')
        using: using

    offsetPx: ->
      offset = if @options.verticalSide == 'bottom' then 10 else -10
      if @options.invertOffset then (offset * -1) else offset

    restoreFocus: ->
      # set focus back to the previously focused item.
      @previousTarget.focus() if @previousTarget and $(@previousTarget).is(':visible')
