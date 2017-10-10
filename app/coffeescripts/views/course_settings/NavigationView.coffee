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
  'jsx/move_item_tray/NewMoveDialogView'
], (I18n, $, Backbone, htmlEscape, NewMoveDialogView) ->
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
      '#move_nav_item_form': '$move_dialog'
      '.navitem' : '$navitems'
      '#move_nav_item_name' : '$move_name'

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
      dialog = @$move_dialog
      which_list = $(e.currentTarget).closest '.nav_list'
      which_item = $(e.currentTarget).closest '.navitem'
      navigationSelectOptions = []
      which_list.children('.navitem').each (key, item) ->
        if $(item).attr('aria-label') is which_item.attr('aria-label')
          return
        navigationSelectOptions.push({ attributes: { id: htmlEscape($(item).attr('id')), name: htmlEscape($(item).attr('aria-label')) } })
      @$move_dialog.data 'current_item', which_item

      currentSelectionModel = {
        attributes: {
          id:  htmlEscape(which_item.attr('id')),
          name: htmlEscape(which_item.attr('aria-label'))
        },
        collection: {
          models: navigationSelectOptions
        }
      }

      @newModalView = new NewMoveDialogView
        model: currentSelectionModel
        nested: false
        closeTarget: which_item.find('a.al-trigger')
        saveURL: ""
        onSuccessfulMove: @onSuccessfulMove
        movePanelParent: document.getElementById('not_right_side')
        modalTitle: I18n.t('Move Navigation Item')
        navigationList: which_list

      @newModalView.renderOpenMoveDialog();

    onSuccessfulMove: (items, action, relativeID) ->
      current_item = $('#move_nav_item_form').data 'current_item'
      before_or_after = action
      selected_item = $('#' + relativeID);
      if action is 'before'
        selected_item.before current_item
      else if action is 'after'
        selected_item.after current_item
      else if action is 'first'
        selected_item.before current_item
      else if action is 'last'
        selected_item.after current_item

    moveSubmit: (e) ->
      e.preventDefault()
      current_item = $('#move_nav_item_form').data 'current_item'
      before_or_after = $('[name="move_location"]:checked').val();
      selected_item = $('#' + $('#move_nav_item_select').val());
      if before_or_after is 'before'
        selected_item.before current_item
      if before_or_after is 'after'
        selected_item.after current_item
      $('#move_nav_item_form').attr('aria-hidden', 'true')
      $('#move_nav_item_form').dialog('close')
      current_item.find('a.al-trigger').focus()

    cancelMove: ->
      current_item = $('#move_nav_item_form').data 'current_item'
      $('#move_nav_item_form').attr('aria-hidden', 'true')
      $('#move_nav_item_form').dialog('close')
      current_item.find('a.al-trigger').focus()

    focusKeyboardHelp: (e) ->
      $('.drag_and_drop_warning').removeClass('screenreader-only')

    hideKeyboardHelp: (e) ->
      $('.drag_and_drop_warning').addClass('screenreader-only')

    afterRender: ->
      @keyCodes = Object.freeze? @keyCodes
      $("li.navitem").on 'keydown', @onKeyDown
      $('#move_nav_item_cancel_btn').on 'click', @cancelMove
      @$move_dialog.on 'submit', @moveSubmit
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
