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
#

define [
  'jquery'
  'Backbone'
  'str/htmlEscape'
  'jqueryui/draggable'
], ($, Backbone, h) ->

  # This is the parent view for <li /> tags inside of an
  # OutcomesDirectoryView. It handles dragging functionality
  # and provides an API for keydown events and for selecting
  # elements.
  class OutcomeIconBase extends Backbone.View

    tagName: 'li'

    attributes:
      tabindex: -1

    events:
      'click':   'triggerSelect'
      'keydown': 'onKeydown'
      'focus':   'onFocus'

    keyCodes:
      13: 'Action'
      32: 'Action'
      37: 'LeftArrow'
      38: 'UpArrow'
      39: 'RightArrow'
      40: 'DownArrow'

    initialize: (opts) ->
      super
      @readOnly = opts.readOnly
      @dir = opts.dir
      @attachEvents()

    # Internal: Attach events to the associated model.
    #
    # Returns nothing.
    attachEvents: ->
      @model.on 'change:title', @updateTitle, this
      @model.on 'remove', @remove, this
      @model.on 'select', @triggerSelect, this

    # Public: Fire a 'select' event for listeners and then select self.
    #
    # "Selecting" an OutcomeIcon involves updating the styles and other display
    # properties, but doesn't impact state at all.
    #
    # e - Event object. (optional)
    #
    # Returns nothing.
    triggerSelect: (e) =>
      e.preventDefault() if e
      @trigger 'select', this
      @select()

    # Internal: Route keydown events to their proper handlers.
    #
    # A handler follows the format "onEnterKey", where "Enter" is the key name.
    #
    # e - Event object.
    #
    # Returns nothing.
    onKeydown: (e) ->
      $target = $(e.target)
      fn      = "on#{@keyCodes[e.keyCode]}Key"
      @[fn].call(this, e, $target) and e.preventDefault() if @[fn]

    # Internal: Navigate to the IconView above this one.
    #
    # Returns nothing.
    onUpArrowKey: (e, $target) -> $target.prev().focus()

    # Internal: Navigate to the IconView below this one.
    #
    # Returns nothing.
    onDownArrowKey: (e, $target) -> $target.next().focus()

    # Internal: Navigate to the previous level.
    #
    # Returns nothing.
    onLeftArrowKey: (e, $target) ->
      return unless $target.parent().prev().length > 0
      @$el.parent().prev().find('[aria-expanded=true]')
                          .click()
                          .attr('aria-expanded', false)
                          .attr('tabindex', 0)
                          .focus()

    # Internal: Trigger a select when enter key is pressed.
    #
    # Returns nothing.
    onActionKey: (e, $target) ->
      if $target.hasClass('outcome-group') then @onRightArrowKey(e, $target) else @triggerSelect()

    # Internal: Update tabindex on $el and its siblings.
    #
    # Returns nothing.
    onFocus: (e) ->
      $target = $(e.target)
      $target.parents('.wrapper:first').find('[tabindex=0]').attr('tabindex', -1)
      $target.attr('tabindex', 0)

    # Internal: Makes an element focusable
    #
    # Returns jQuery element
    makeFocusable: ->
      @$el.parent().find('[tabindex=0]').attr('tabindex', -1)
      @$el.attr('tabindex', 0)

    # Internal: Add selected class to <li />.
    #
    # Returns jQuery element.
    select: =>
      @makeFocusable()
      @$el.addClass('selected')

    # Internal: Remove selected class to <li />.
    #
    # Returns jQuery element.
    unSelect: ->
      @$el.removeClass 'selected'

    # Internal: Clean up event handlers prior to destroying object.
    #
    # Returns nothing.
    remove: ->
      @model.off 'change:title', @updateTitle, this
      @model.off 'remove', @remove, this
      @model.off 'select', @triggerSelect, this
      super

    # Public: Update display title to match the model's title.
    #
    # Returns nothing.
    updateTitle: ->
      @$('span').text @model.get 'title'
      @$('a').attr('title', h(@model.get 'title'))

    # Public: Init dragging and render view.
    #
    # Returns self.
    render: ->
      @initDraggable() unless @readOnly
      @$el.data 'view', this
      this

    # Internal: Set up jQuery dragging and store view ref. on the element.
    #
    # Returns nothing.
    initDraggable: ->
      @$el.draggable
        scope: 'outcomes'
        containment: '.outcomes-sidebar'
        opacity: 0.7
        helper: 'clone'
        revert: 'invalid'
        scroll: false
        drag: (event, ui) ->
          i = $(this).data("draggable")
          o = i.options
          scrolled = false
          sidebar = i.relative_container
          sidebarOffsetLeft = sidebar.offset().left
          sidebarWidth = sidebar.width()

          if event.pageX - sidebarOffsetLeft < o.scrollSensitivity
            sidebar[0].scrollLeft = scrolled = sidebar[0].scrollLeft - o.scrollSpeed
          else if (sidebarOffsetLeft + sidebarWidth) - event.pageX < o.scrollSensitivity
            sidebar[0].scrollLeft = scrolled = sidebar[0].scrollLeft + o.scrollSpeed

          if scrolled isnt false and $.ui.ddmanager and !o.dropBehaviour
            $.ui.ddmanager.prepareOffsets i, event
