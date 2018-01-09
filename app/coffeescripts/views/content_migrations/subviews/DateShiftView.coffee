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
  './DaySubstitutionView'
  '../../../models/DaySubstitution'
  'jst/content_migrations/subviews/DateShift'
], ($, Backbone, DaySubView, DaySubModel, template) ->
  class DateShiftView extends Backbone.View
    template: template

    @child 'daySubstitution', '#daySubstitution'
    @optionProperty 'oldStartDate'
    @optionProperty 'oldEndDate'
    @optionProperty 'addHiddenInput'

    els:
      ".dateAdjustContent" : "$dateAdjustContent"
      "#dateAdjustCheckbox": "$dateAdjustCheckbox"
      ".dateShiftContent"  : "$dateShiftContent"
      "#dateShiftOption"   : "$dateShiftOption"
      "#oldStartDate"      : "$oldStartDate"
      "#oldEndDate"        : "$oldEndDate"
      "#newStartDate"      : "$newStartDate"
      "#newEndDate"        : "$newEndDate"
      "#daySubstitution"   : "$daySubstitution"

    events:
      'click #dateAdjustCheckbox' : 'toggleContent'
      'click #dateRemoveOption'   : 'toggleShiftContent'
      'click #dateShiftOption'    : 'toggleShiftContent'
      'click #addDaySubstitution' : 'createDaySubView'

    afterRender: ->
      @$el.find('input[type=text]').datetime_field(addHiddenInput: @addHiddenInput)

      @$newStartDate.val(@oldStartDate).trigger('change') if @oldStartDate
      @$newEndDate.val(@oldEndDate).trigger('change') if @oldEndDate

      @collection.on 'remove', => @$el.find('#addDaySubstitution').focus()
      @toggleContent()

    # Toggle adjust-dates content. Shows Shift/Remove radio buttons
    # if "Adjust dates" is checked.

    toggleContent: =>
      adjustDates = @$dateAdjustCheckbox.is(':checked')
      @toggleShiftContent() if adjustDates
      @$dateAdjustContent.toggle(adjustDates)


    # Toggle shift content. Shows content when the "Shift dates" radio button
    # is selected, and hides content otherwise
    #
    # @expects jQuery event
    # @returns void
    # @api private

    toggleShiftContent: =>
      dateShift = @$dateShiftOption.is(':checked')
      @model.daySubCollection = if dateShift then @collection else null
      @$dateShiftContent.toggle(dateShift)

    # Displays a new DaySubstitutionView by adding it to the collection.
    # @api private

    createDaySubView: (event) =>
      event.preventDefault()
      @collection.add new DaySubModel

      # Focus on the last date substitution added
      $lastDaySubView = @collection.last()?.view.$el
      $lastDaySubView.find('select').first().focus()


    updateNewDates: (course) =>
      @$oldStartDate.val(course.start_at).trigger('change')
      @$oldEndDate.val(course.end_at).trigger('change')
