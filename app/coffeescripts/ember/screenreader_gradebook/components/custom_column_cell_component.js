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

define [
  'ember'
  'underscore'
  '../../../gradebook/GradebookHelpers'
  'jsx/gradebook/shared/constants'
], (Ember, _, GradebookHelpers, GradebookConstants) ->

  CustomColumnCellComponent = Ember.Component.extend

    column: null
    student: null
    dataForStudent: null
    id: (->
      "custom_col_#{@get('column.id')}"
    ).property('column')

    dataForColumn: (->
      studentData = @get('dataForStudent')
      return null unless studentData
      studentData.findBy('column_id', @get('column.id'))
    ).property('student', 'column', 'column.isLoaded', 'dataForStudent.@each.content')

    contentDidChange: (->
       @set('value', @get('dataForColumn.content'))
    ).observes('dataForColumn.content').on('didInsertElement')

    ajax: (url, options) ->
      {type, data} = options
      Ember.$.ajaxJSON url, type, data

    customColURL: ->
      ENV.GRADEBOOK_OPTIONS.custom_column_datum_url

    disabled:(->
      @get('column.isLoading') || @get('column.read_only')
    ).property('column', 'column.isLoading', 'column.read_only')

    saveURL: (->
       @customColURL()
         .replace(/:id/, @get('column.id'))
         .replace(/:user_id/, @get('student.id'))
    ).property('column', 'student')

    focusOut: ->
      value = @$('textarea').val()
      return if (value == "" and !@get('dataForColumn')) or value == @get('dataForColumn.content')
      @get('dataForColumn.content')
      xhr = @ajax @get('saveURL'),
        type: "PUT"
        data:"column_data[content]": value

      xhr.then @boundSaveSuccess

    textAreaInput: ((event) ->
      note = event.target.value
      if GradebookHelpers.textareaIsGreaterThanMaxLength(note.length)
        event.target.value = note.substring(0, GradebookConstants.MAX_NOTE_LENGTH)
        showError = GradebookHelpers.maxLengthErrorShouldBeShown(note.length)
        GradebookHelpers.flashMaxLengthError() if showError
    ).on('input')

    bindSave: (->
      @boundSaveSuccess = _.bind(@onSaveSuccess, this)
    ).on('init')

    onSaveSuccess: (columnDatum) ->
      @sendAction 'on-column-save', columnDatum, @get('column.id')
