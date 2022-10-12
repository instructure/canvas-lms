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

import $ from 'jquery'
import Ember from 'ember'
import startApp from '../start_app'
import fixtures from '../ajax_fixtures'
import GradebookHelpers from '../../../helpers'
import GradebookConstants from '../../../constants'

const {run} = Ember

QUnit.module('custom_column_cell', {
  setup() {
    fixtures.create()
    const App = startApp()
    this.component = App.CustomColumnCellComponent.create()

    this.component.reopen({
      customColURL() {
        return '/api/v1/custom_gradebook_columns/:id/:user_id'
      },
    })
    return run(() => {
      this.column = Ember.Object.create({
        id: '22',
        title: 'Notes',
        read_only: false,
        is_loading: false,
      })
      this.student = Ember.Object.create({
        id: '45',
      })
      this.dataForStudent = [
        Ember.Object.create({
          column_id: '22',
          content: 'lots of content here',
        }),
      ]
      this.component.setProperties({
        student: this.student,
        column: this.column,
        dataForStudent: this.dataForStudent,
      })
      return this.component.append()
    })
  },

  teardown() {
    return run(() => {
      this.component.destroy()
      return App.destroy()
    })
  },
})

test('id', function () {
  equal(this.component.get('id'), 'custom_col_22')
})

test('value', function () {
  equal(this.component.get('value'), 'lots of content here')
})

test('saveUrl', function () {
  equal(this.component.get('saveURL'), '/api/v1/custom_gradebook_columns/22/45')
})

test('disabled is true when column isLoading', function () {
  this.component.column.set('isLoading', true)
  this.component.column.set('read_only', false)
  equal(this.component.get('disabled'), true)
})

test('disabled is true when column is read_only', function () {
  this.component.column.set('isLoading', false)
  this.component.column.set('read_only', true)
  equal(this.component.get('disabled'), true)
})

test('disabled is false when column is not loading and not read_only', function () {
  this.component.column.set('isLoading', false)
  this.component.column.set('read_only', false)
  equal(this.component.get('disabled'), false)
})

test('focusOut', function (assert) {
  assert.expect(1)
  const stub = sandbox.stub(this.component, 'boundSaveSuccess')

  let requestStub = null
  run(
    () =>
      (requestStub = Ember.RSVP.resolve({
        id: '22',
        title: 'Notes',
        content: 'less content now',
      }))
  )

  sandbox.stub(this.component, 'ajax').returns(requestStub)

  run(() => {
    this.component.set('value', 'such success')
    return this.component.send('focusOut')
  })

  ok(stub.called)
})

test('textAreaInput does not flash an error if note length is exactly the max allowed length', function () {
  const note = 'a'.repeat(GradebookConstants.MAX_NOTE_LENGTH)
  const noteInputEvent = {target: {value: note}}
  const maxLengthError = sandbox.spy(GradebookHelpers, 'flashMaxLengthError')
  this.component.textAreaInput(noteInputEvent)
  ok(maxLengthError.notCalled)
})

test('textAreaInput flashes an error if note length is greater than the max allowed length', function () {
  const note = 'a'.repeat(GradebookConstants.MAX_NOTE_LENGTH + 1)
  const noteInputEvent = {target: {value: note}}
  const maxLengthError = sandbox.spy(GradebookHelpers, 'flashMaxLengthError')
  this.component.textAreaInput(noteInputEvent)
  ok(maxLengthError.calledOnce)
})

test('textAreaInput does not flash an error if there is already an error showing, even if note length is greater than the max allowed length', function () {
  const note = 'a'.repeat(GradebookConstants.MAX_NOTE_LENGTH + 1)
  const noteInputEvent = {target: {value: note}}
  const maxLengthError = sandbox.spy(GradebookHelpers, 'flashMaxLengthError')
  const findStub = sandbox.stub($, 'find')
  findStub.withArgs('.ic-flash-error').returns(['a non-empty error array'])
  this.component.textAreaInput(noteInputEvent)
  ok(maxLengthError.notCalled)
})
