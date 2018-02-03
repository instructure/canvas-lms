#
# Copyright (C) 2013 - present Instructure, Inc.
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
  'Backbone'
  '../../../jquery/outerclick'
], ($, {View}) ->

  class PopoverMenuView extends View

    defaults:
      zIndex: 1

    events:
      'mousedown': 'disableHide'
      'mouseup': 'enableHide'
      'click': 'cancelHide'
      'focusin': 'cancelHide'
      'focusout': 'hidePopover'
      'outerclick': 'hidePopover'
      'keyup': 'checkEsc'

    disableHide: ->
      @hideDisabled = true

    enableHide: ->
      @hideDisabled = false

    hidePopover: ->
      @hide() unless @hideDisabled #call the hide function without any arguments.

    showBy: ($target, focus = false) ->
      @cancelHide()
      setTimeout => # IE needs this to happen async frd
        @render()
        @attachElement($target)
        @$el.show()
        @setElement @$el
        @$el.zIndex(@options.zIndex)
        @setWidth?()
        @$el.position
          my: @my or 'left+6 top-47'
          at: @at or 'right center'
          of: $target
          collision: 'none'
          using: (coords) =>
            content = @$el.find '.popover-content'
            @$el.css top: coords.top, left: coords.left
            @setPopoverContentHeight(@$el, content, $('#content'))

        @focus?() if focus
        @trigger("open", { "target" : $target })
      , 20

    setPopoverContentHeight: (popover, content, parent) ->
      parentBound = parent.offset().top + parent.height()
      popoverOffset = popover.offset().top
      popoverHeader = popover.find('.popover-title').outerHeight()
      defaultHeight = parseInt content.css('maxHeight')
      newHeight = parentBound - popoverOffset - popoverHeader
      content.css maxHeight: Math.min(defaultHeight, newHeight)

    cancelHide: =>
      clearTimeout @hideTimeout

    hide: (escapePressed = false) =>
      @hideTimeout = setTimeout =>
        @$el.detach()
        @trigger("close", {"escapePressed": escapePressed})
      , 100

    checkEsc: (e) ->
      @hide(true) if e.keyCode is 27 # escape

    attachElement: ($target) ->
      @$el.insertAfter($target)
