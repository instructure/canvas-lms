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
  'underscore'
  'Backbone'
  'i18n!calendar.edit'
  'jst/calendar/missingDueDateDialog'
  'str/htmlEscape'
  'jqueryui/dialog'
  '../../jquery/fixDialogButtons'
], ($, _, {View}, I18n, template, htmlEscape) ->

  class MissingDateDialogView extends View
    dialogTitle: """
      <span>
        <i class="icon-warning"></i>
        #{htmlEscape I18n.t('titles.warning', 'Warning')}
      </span>
    """

    initialize: (options) ->
      super
      @validationFn = options.validationFn
      @labelFn      = options.labelFn or @defaultLabelFn
      @success      = options.success

    defaultLabelFn: (input) ->
      $("label[for=#{$(input).attr('id')}]").text()

    render: ->
      @invalidFields = @validationFn()
      if @invalidFields == true
        false
      else
        @invalidSectionNames = _.map(@invalidFields, @labelFn)
        @showDialog()
        this

    getInvalidFields: ->
      invalidDates = _.select(@$dateFields, (date) -> $(date).val() is '')
      sectionNames = _.map(invalidDates, @labelFn)

      if sectionNames.length > 0
        [invalidDates, sectionNames]
      else
        false

    showDialog: ->
      description = I18n.t('missingDueDate', {
        one  : '%{sections} does not have a due date assigned.'
        other: '%{sections} do not have a due date assigned.'
      }, {
        sections: ''
        count: @invalidSectionNames.length
      })

      tpl = template(description: description, sections: @invalidSectionNames)
      @$dialog = $(tpl).dialog
        dialogClass: 'dialog-warning'
        draggable  : false
        modal      : true
        resizable  : false
        title      : $(@dialogTitle)
      .fixDialogButtons()
      .on('click', '.btn', @onAction)
      @$dialog.parents('.ui-dialog:first').focus()

    onAction: (e) =>
      if $(e.currentTarget).hasClass('btn-primary')
        @success(@$dialog)
      else
        @cancel(@invalidFields, @sectionNames)

    cancel: (e) =>
      if @$dialog? && @$dialog.data("dialog")
        @$dialog.dialog('close').remove()
      if @invalidFields[0]?
        @invalidFields[0].focus()
