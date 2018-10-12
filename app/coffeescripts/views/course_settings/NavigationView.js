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
  'i18n!course_navigation'
  'jquery'
  'Backbone'
  'str/htmlEscape'
  'jsx/move_item'
], (I18n, $, Backbone, htmlEscape, MoveItem) ->
  ###
  xsslint jqueryObject.identifier dragObject current_item
  ###

  class NavigationView extends Backbone.View

    keyCodes:
      32: 'Space'
      38: 'UpArrow'
      40: 'DownArrow'

    events:
      'click .disable_nav_item_link': 'disableNavLink'
      'click .move_nav_item_link'   : 'moveNavLink'
      'click .enable_nav_item_link' : 'enableNavLink'

    els:
      '#nav_enabled_list' : '$enabled_list'
      '#nav_disabled_list' : '$disabled_list'
      '.navitem' : '$navitems'

    disableNavLink: (e) ->
      $targetItem = $(e.currentTarget).closest('.navitem')
      @$disabled_list.append($targetItem)
      $(e.currentTarget)
        .attr('class', '')
        .attr('class', 'icon-plus enable_nav_item_link')
        .text("Enable")
      $targetItem.find('a.al-trigger').focus()

    enableNavLink: (e) ->
      $targetItem = $(e.currentTarget).closest('.navitem')
      @$enabled_list.append($targetItem)
      $(e.currentTarget)
        .attr('class', '')
        .attr('class', 'icon-x disable_nav_item_link')
        .text("Disable")
      $targetItem.find('a.al-trigger').focus()

    moveNavLink: (e) ->
      selectedItem = $(e.currentTarget).closest '.navitem'
      navList = $(e.currentTarget).closest '.nav_list'
      navOptions = navList.children('.navitem').map (key, item) ->
        id: item.getAttribute('id')
        title: item.getAttribute('aria-label')
      .toArray()

      @moveTrayProps =
        title: I18n.t('Move Navigation Item')
        items: [
          id: selectedItem.attr('id')
          title: selectedItem.attr('aria-label')
        ]
        moveOptions:
          siblings: navOptions
        onMoveSuccess: (res) =>
          MoveItem.reorderElements(res.data, @$enabled_list[0], (id) => '#' + id)
        focusOnExit: (item) => document.querySelector("##{item.id} a.al-trigger")

      MoveItem.renderTray(@moveTrayProps, document.getElementById('not_right_side'))

    focusKeyboardHelp: (e) ->
      $('.drag_and_drop_warning').removeClass('screenreader-only')

    hideKeyboardHelp: (e) ->
      $('.drag_and_drop_warning').addClass('screenreader-only')

    afterRender: ->
      @keyCodes = Object.freeze? @keyCodes
      $("li.navitem").on 'keydown', @onKeyDown
      $('#navigation_tab').on 'blur', @focusKeyboardHelp
      $('.drag_and_drop_warning').on 'blur', @hideKeyboardHelp

    onKeyDown: (e) =>
      $target = $(e.target)
      fn      = "on#{@keyCodes[e.keyCode]}Key"
      @[fn].call(this, e, $target) and e.preventDefault() if @[fn]

    # Internal: move to the previous element
    # or up to the enabled list if at the top of the disabled list
    # returns nothing
    onUpArrowKey: (e, $target) ->
      prev = $target.prev("li.navitem")

      if @empty(prev)
        prev = $target.children("li.navitem").first()

      if @empty(prev) && @disabled($target)
        prev = @$enabled_list.children("li.navitem").last()

        if @empty(prev)
          prev = @$enabled_list
          prev.attr('tabindex', 0)
          prev.bind 'keydown', @onKeyDown

      prev.focus()

    # Internal: move to the next element
    # or down to the disabled list if at the bottom of the enabled list
    # returns nothing
    onDownArrowKey: (e, $target) ->
      next = $target.next("li.navitem")

      if @empty(next)
        next = $target.children("li.navitem").first()

      if @empty(next) && @enabled($target)
        next = @$disabled_list.children("li.navitem").first()

        if @empty(next)
          next = @$disabled_list
          next.attr('tabindex', -1)
          next.bind 'keydown', @onKeyDown

      next.focus()

    # Internal: mark the current element to begin dragging
    # or drop the current element
    # returns nothing
    onSpaceKey: (e, $target) ->
      if dragObject = @$el.data('drag')
        unless $target.is(dragObject)
          # drop
          if $target.is('li.navitem')
            $target.after(dragObject)
          else
            $target.append(dragObject)
            $target.attr('tabindex', -1)
            $target.unbind('keydown')

        dragObject.attr('aria-grabbed', false)
        @$el.data('drag', null)
        dragObject.focus()
      else if $target.is('li.navitem')
        $target.attr('aria-grabbed', true)
        dragObject = $target
        @$el.data('drag', dragObject)
        dragObject.blur()
        dragObject.focus()

    # Internal: returns whether the selector is empty
    empty: (selector) ->
      selector.length == 0

    # Internal: returns whether the element is inside the enabled list
    enabled: (el) ->
      el.parent().attr("id") == @$enabled_list.attr("id")

    # Internal: returns whether the element is inside the enabled list
    disabled: (el) ->
      el.parent().attr("id") == @$disabled_list.attr("id")
