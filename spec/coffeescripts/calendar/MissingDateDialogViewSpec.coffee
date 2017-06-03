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
  'compiled/views/calendar/MissingDateDialogView'
], ($, MissingDateDialogView) ->

  QUnit.module 'MissingDateDialogView',
    setup: ->
      $('#fixtures').append('<label for="date">Section one</label><input type="text" id="date" name="date" />')
      @dialog = new MissingDateDialogView
        validationFn: ->
          invalidFields = []
          $('input[name=date]').each ->
            invalidFields.push($(this)) if $(this).val() == ''
          if invalidFields.length > 0 then invalidFields else true
        success: @spy()

    teardown: ->
      @dialog.cancel({})
      $('input[name=date]').remove()
      $('label[for=date]').remove()
      $('.ui-dialog').remove()
      $("#fixtures").empty()

  test 'should display a dialog if the given fields are invalid', ->
    ok @dialog.render()
    ok $('.ui-dialog:visible').length > 0

  test 'it should list the names of the sections w/o dates', ->
    @dialog.render()
    ok $('.ui-dialog').text().match(/Section one/)

  test 'should not display a dialog if the given fields are valid', ->
    $('input[name=date]').val('2013-01-01')
    equal @dialog.render(), false
    equal $('.ui-dialog').length, 0

  test 'should close the dialog on secondary button press', ->
    @dialog.render()
    @dialog.$dialog.find('.btn:not(.btn-primary)').click()
    equal $('.ui-dialog').length, 0

  test 'should run the success callback on on primary button press', ->
    @dialog.render()
    @dialog.$dialog.find('.btn-primary').click()
    ok @dialog.options.success.calledOnce
