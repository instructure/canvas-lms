#
# Copyright (C) 2014 Instructure, Inc.
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
  'i18n!gradezilla'
  'compiled/gradezilla/GradebookTranslations'
  'jquery.keycodes'
], (I18n, GRADEBOOK_TRANSLATIONS) ->
  class GradebookKeyboardNav
    constructor: (@slickGrid, @$grid) ->

    init: ->
      for binding in @keyBindings
        if binding.handler? && binding.key? && @[binding.handler]?
          @$grid.keycodes(binding.key, @[binding.handler])

    getHeaderFromActiveCell: =>
      coords = @slickGrid.getActiveCell()
      @$grid.find('.slick-header-column').eq(coords.cell)

    sortOnHeader: =>
      @getHeaderFromActiveCell().click()

    showAssignmentMenu: =>
      @getHeaderFromActiveCell().find('.gradebook-header-drop').click()
      $('.gradebook-header-menu:visible').focus()

    gotoAssignment: =>
      url = @getHeaderFromActiveCell().find('.assignment-name').attr('href')
      window.location = url

    showCommentDialog: =>
      commentingIsDisabled = $(@slickGrid.getActiveCellNode()).hasClass("cannot_edit")
      return if commentingIsDisabled
      $(@slickGrid.getActiveCellNode()).find('.gradebook-cell-comment').click()

    showToolTip: =>
      node = $(@slickGrid.getActiveCellNode())
      if node.parent().css('top') == '0px'
        node.find('div.gradebook-tooltip').addClass('first-row')
      else
        node.find('div.gradebook-tooltip').removeClass('first-row')
      node.toggleClass("hover")

    keyBindings:
      #   handler: function
      #   key: the string representation of the key pressed - for use in the help dialog
      #   desc: string describing what the shortcut does - for use in the help dialog
      [
        {
        handler: 'sortOnHeader'
        key: I18n.t 'keycodes.sort', 's'
        desc: I18n.t 'keyboard_sort_desc', 'Sort the grid on the current active column'
        }
        {
        handler: 'showAssignmentMenu'
        key: I18n.t 'keycodes.menu', 'm'
        desc: I18n.t 'keyboard_menu_desc', 'Open the menu for the active column\'s assignment'
        }
         # this one is just for display in the dialog, the menu will take care of itself
        {
        key: I18n.t 'keycodes.close_menu', 'esc'
        desc: I18n.t 'keyboard_close_menu', 'Close the currently active assignment menu'
        }

        {
        handler: 'gotoAssignment'
        key: I18n.t 'keycodes.goto_assignment', 'g'
        desc: I18n.t 'keyboard_assignment_desc', 'Go to the current assignment\'s detail page'
        }
        {
        handler: 'showCommentDialog'
        key: I18n.t 'keycodes.comment', 'c'
        desc: I18n.t 'keyboard_comment_desc', 'Comment on the active submission'
        }
        {
        handler: 'showToolTip'
        key: I18n.t 'keycodes.tooltip', 't'
        desc: I18n.t 'keyboard_tooltip_desc', 'Show the submission type of the active submission'
        }
      ]

