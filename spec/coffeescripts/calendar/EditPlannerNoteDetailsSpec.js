/*
 * Copyright (C) 2015 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import $ from 'jquery'
import 'jquery-migrate'
import EditPlannerNoteDetails from 'ui/features/calendar/backbone/views/EditPlannerNoteDetails'
import tzInTest from '@canvas/datetime/specHelpers'
import fakeENV from 'helpers/fakeENV'
import commonEventFactory from '@canvas/calendar/jquery/CommonEvent/index'

const fixtures = $('#fixtures')
const note = {
  id: '5',
  todo_date: '2017-07-22T00:00:00-05',
  title: 'A To Do',
  details: 'the deets',
  user_id: '1',
  course_id: null,
  workflow_state: 'active',
  type: 'planner_note',
  context_code: 'user_1',
  all_context_codes: 'user_1',
}

QUnit.module('EditPlannerNoteDetails', {
  setup() {
    this.$holder = $('<table />').appendTo(document.getElementById('fixtures'))
    fakeENV.setup({TIMEZONE: 'America/Chicago'})
  },
  teardown() {
    this.$holder.detach()
    document.getElementById('fixtures').innerHTML = ''
    fakeENV.teardown()
    tzInTest.restore()
  },
})
const createView = function (event = note) {
  return new EditPlannerNoteDetails(fixtures, event, null, null)
}
const commonEvent = () => commonEventFactory(note, [{asset_string: 'user_1'}])

test('should initialize input with start date', () => {
  const view = createView(commonEvent())
  equal(view.$('.date_field').val(), 'Sat, Jul 22, 2017')
})

test('should localize start date', () => {
  ENV.LOCALE = 'fr' // fakeENV.teardown() will clean this up
  const view = createView(commonEvent())
  equal(view.$('.date_field').val(), 'sam. 22 juil. 2017')
})

test('requires name to save assignment note', () => {
  const data = {
    ...note,
  }
  data.title = ''
  const view = createView(commonEvent(data))
  const errors = view.validateBeforeSave(data, [])
  ok(errors.title)
  equal(errors.title.length, 1)
  equal(errors.title[0].message, 'Title is required!')
})

test('requires todo_date to save note', () => {
  const data = {
    ...note,
  }
  data.todo_date = ''
  const view = createView(commonEvent(data))
  const errors = view.validateBeforeSave(data, [])
  ok(errors.date)
  equal(errors.date.length, 1)
  equal(errors.date[0].message, 'Date is required!')
})

test('requires todo_date not to be in the past', () => {
  const data = {
    ...note,
  }
  const d = new Date()
  d.setDate(d.getDate() - 1)
  data.todo_date = d
  const view = createView(commonEvent(data))
  const errors = view.validateBeforeSave(data, [])
  equal(errors.length, 0)
})
