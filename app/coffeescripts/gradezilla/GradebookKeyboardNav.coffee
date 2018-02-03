#
# Copyright (C) 2014 - present Instructure, Inc.
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
  '../gradezilla/GradebookTranslations'
  'jquery'
  'jquery.keycodes'
], (I18n, GRADEBOOK_TRANSLATIONS, $) ->
  class GradebookKeyboardNav
    constructor: (@options) ->
      @gridSupport = @options.gridSupport
      @gradebookElements = [document.querySelector('#gradebook_grid')]
      @sortOnHeader = @preprocessKeydown(@sortOnHeader)
      @toggleColumnHeaderMenu = @preprocessKeydown(@toggleColumnHeaderMenu, true)
      @gotoAssignment = @preprocessKeydown(@gotoAssignment)
      @showSubmissionTray = @preprocessKeydown(@showSubmissionTray)

    init: ->
      for binding in @keyBindings
        if binding.handler? && binding.key? && @[binding.handler]?
          $(document.body).keycodes(binding.key, @[binding.handler])

    shouldHandleEvent: (e) =>
      for element in @gradebookElements
        return true if element.contains(e.target)

      false

    haveLocation: (usePrevActiveLocation) =>
      return true if @gridSupport.state.getActiveLocation().cell?
      usePrevActiveLocation && @prevActiveLocation?

    preprocessKeydown: (handler, usePrevActiveLocation) =>
      (e) =>
        return unless @shouldHandleEvent(e)
        return unless @haveLocation(usePrevActiveLocation)

        handler(e)

    currentRegion: =>
      @gridSupport.state.getActiveLocation().region

    currentColumnId: =>
      @gridSupport.state.getActiveLocation().columnId

    currentColumnType: =>
      @options.getColumnTypeForColumnId(@currentColumnId())

    handleMenuOrDialogClose: =>
      return unless @prevActiveLocation?

      if @prevActiveLocation.region == 'header'
        @gridSupport.state.setActiveLocation(@prevActiveLocation.region, @prevActiveLocation)
        @prevActiveElement.focus()
      else
        @gridSupport.state.setActiveLocation(@prevActiveLocation.region, @prevActiveLocation)
        @gridSupport.helper.commitCurrentEdit() if @currentColumnType() == 'assignment'
        @gridSupport.helper.focus()

      @prevActiveLocation = null
      @prevActiveElement = null

    addGradebookElement: (element) =>
      @gradebookElements.push(element) unless @gradebookElements.includes(element)

    removeGradebookElement: (element) =>
      @gradebookElements = @gradebookElements.filter (e) -> e != element

    getHeaderFromActiveCell: =>
      header = @gridSupport.state.getActiveColumnHeaderNode()

      if !header && @prevActiveLocation?.cell?
        header = @gridSupport.state.getColumnHeaderNode(@prevActiveLocation.cell)

      header

    sortOnHeader: =>
      @options.toggleDefaultSort(@currentColumnId())

      activeLocation = @gridSupport.state.getActiveLocation()

      if @currentColumnType() == 'student' && activeLocation.region == 'body'
        @gridSupport.state.setActiveLocation(activeLocation.region, activeLocation)

    toggleColumnHeaderMenu: (e) =>
      # Prevent sending keystroke to text input of editable cells
      e.preventDefault()
      activeLocation = @gridSupport.state.getActiveLocation()

      if activeLocation.cell? && !@prevActiveLocation
        @prevActiveLocation = activeLocation
        @prevActiveElement = document.activeElement

      @getHeaderFromActiveCell().querySelector('.Gradebook__ColumnHeaderAction button')?.click()

    gotoAssignment: =>
      return unless @currentColumnType() == 'assignment'
      url = @getHeaderFromActiveCell().querySelector('.assignment-name a').href
      window.location = url

    showSubmissionTray: =>
      return unless @currentRegion() == 'body' && @currentColumnType() == 'assignment'

      activeLocation = @gridSupport.state.getActiveLocation()
      assignmentId = @gridSupport.grid.getColumns()[activeLocation.cell]?.assignmentId
      studentId = @gridSupport.options.rows[activeLocation.row]?.id

      @options.openSubmissionTray(studentId, assignmentId) if studentId? && assignmentId?

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
        handler: 'toggleColumnHeaderMenu'
        key: I18n.t 'keycodes.menu', 'm'
        desc: I18n.t 'keyboard_menu_desc', 'Open menu for the active column'
        }
         # this one is just for display in the dialog, the menu will take care of itself
        {
        key: I18n.t 'keycodes.close_menu', 'esc'
        desc: I18n.t 'keyboard_close_menu', 'Close the currently active menu'
        }

        {
        handler: 'gotoAssignment'
        key: I18n.t 'keycodes.goto_assignment', 'g'
        desc: I18n.t 'keyboard_assignment_desc', 'Go to the current assignment\'s detail page'
        }
        {
        handler: 'showSubmissionTray'
        key: 'c'
        desc: I18n.t 'Open the grade detail tray'
        }
      ]
