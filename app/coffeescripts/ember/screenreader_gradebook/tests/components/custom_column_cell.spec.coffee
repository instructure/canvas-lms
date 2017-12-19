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
  'jquery'
  'ember'
  '../start_app'
  '../shared_ajax_fixtures'
  '../../../../gradebook/GradebookHelpers'
  'jsx/gradebook/shared/constants'
], ($, Ember, startApp, fixtures, GradebookHelpers, GradebookConstants) ->

  {run} = Ember

  setType = null

  QUnit.module 'custom_column_cell',
    setup: ->
      fixtures.create()
      App = startApp()
      @component = App.CustomColumnCellComponent.create()

      @component.reopen
        customColURL: ->
          "/api/v1/custom_gradebook_columns/:id/:user_id"
      run =>
        @column = Ember.Object.create
          id: '22'
          title: 'Notes'
        @student = Ember.Object.create
          id: '45'
        @dataForStudent = [
          Ember.Object.create {
            column_id: '22'
            content: 'lots of content here'
          }
        ]
        @component.setProperties
          student: @student
          column: @column
          dataForStudent: @dataForStudent
        @component.append()

    teardown: ->
      run =>
        @component.destroy()
        App.destroy()

  test "id", ->
    equal @component.get('id'), 'custom_col_22'

  test "value", ->
    equal @component.get('value'), 'lots of content here'

  test "saveUrl", ->
    equal @component.get('saveURL'), '/api/v1/custom_gradebook_columns/22/45'

  test "focusOut", (assert) ->
    assert.expect(1)
    stub = @stub @component, 'boundSaveSuccess'

    requestStub = null
    run =>
      requestStub = Ember.RSVP.resolve(
        id: '22'
        title: 'Notes'
        content: 'less content now'
      )

    @stub(@component, 'ajax').returns requestStub

    run =>
      @component.set('value', 'such success')
      @component.send('focusOut')

    ok stub.called

  test "textAreaInput does not flash an error if note length is exactly the max allowed length", ->
    note = 'a'.repeat(GradebookConstants.MAX_NOTE_LENGTH)
    noteInputEvent = {target: {value: note}}
    maxLengthError = @spy(GradebookHelpers, 'flashMaxLengthError')
    @component.textAreaInput(noteInputEvent)
    ok maxLengthError.notCalled

  test "textAreaInput flashes an error if note length is greater than the max allowed length", ->
    note = 'a'.repeat(GradebookConstants.MAX_NOTE_LENGTH + 1)
    noteInputEvent = {target: {value: note}}
    maxLengthError = @spy(GradebookHelpers, 'flashMaxLengthError')
    @component.textAreaInput(noteInputEvent)
    ok maxLengthError.calledOnce

  test "textAreaInput does not flash an error if there is already an error showing,
  even if note length is greater than the max allowed length", ->
    note = 'a'.repeat(GradebookConstants.MAX_NOTE_LENGTH + 1)
    noteInputEvent = {target: {value: note}}
    maxLengthError = @spy(GradebookHelpers, 'flashMaxLengthError')
    findStub = @stub($, 'find')
    findStub.withArgs('.ic-flash-error').returns(['a non-empty error array'])
    @component.textAreaInput(noteInputEvent)
    ok maxLengthError.notCalled
