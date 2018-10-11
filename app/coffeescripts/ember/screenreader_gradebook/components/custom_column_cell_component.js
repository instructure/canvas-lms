//
// Copyright (C) 2014 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import Ember from 'ember'
import _ from 'underscore'
import GradebookHelpers from '../../../gradebook/GradebookHelpers'
import GradebookConstants from 'jsx/gradebook/shared/constants'

const CustomColumnCellComponent = Ember.Component.extend({
  column: null,
  student: null,
  dataForStudent: null,
  id: function() {
    return `custom_col_${this.get('column.id')}`
  }.property('column'),

  dataForColumn: function() {
    const studentData = this.get('dataForStudent')
    if (!studentData) {
      return null
    }
    return studentData.findBy('column_id', this.get('column.id'))
  }.property('student', 'column', 'column.isLoaded', 'dataForStudent.@each.content'),

  contentDidChange: function() {
    return this.set('value', this.get('dataForColumn.content'))
  }
    .observes('dataForColumn.content')
    .on('didInsertElement'),

  ajax(url, options) {
    const {type, data} = options
    return Ember.$.ajaxJSON(url, type, data)
  },

  customColURL() {
    return ENV.GRADEBOOK_OPTIONS.custom_column_datum_url
  },

  disabled: function() {
    return this.get('column.isLoading') || this.get('column.read_only')
  }.property('column', 'column.isLoading', 'column.read_only'),

  saveURL: function() {
    return this.customColURL()
      .replace(/:id/, this.get('column.id'))
      .replace(/:user_id/, this.get('student.id'))
  }.property('column', 'student'),

  focusOut() {
    const value = this.$('textarea').val()
    if (
      (value === '' && !this.get('dataForColumn')) ||
      value === this.get('dataForColumn.content')
    ) {
      return
    }
    this.get('dataForColumn.content')
    const xhr = this.ajax(this.get('saveURL'), {
      type: 'PUT',
      data: {
        'column_data[content]': value
      }
    })

    return xhr.then(this.boundSaveSuccess)
  },

  textAreaInput: function(event) {
    const note = event.target.value
    if (GradebookHelpers.textareaIsGreaterThanMaxLength(note.length)) {
      event.target.value = note.substring(0, GradebookConstants.MAX_NOTE_LENGTH)
      const showError = GradebookHelpers.maxLengthErrorShouldBeShown(note.length)
      if (showError) {
        return GradebookHelpers.flashMaxLengthError()
      }
    }
  }.on('input'),

  bindSave: function() {
    return (this.boundSaveSuccess = _.bind(this.onSaveSuccess, this))
  }.on('init'),

  onSaveSuccess(columnDatum) {
    return this.sendAction('on-column-save', columnDatum, this.get('column.id'))
  }
})

export default CustomColumnCellComponent
