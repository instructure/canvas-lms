#
# Copyright (C) 2015 - present Instructure, Inc.
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
  'Backbone',
  'underscore',
  'jquery'
  'compiled/calendar/EditPlannerNoteDetails'
  'compiled/util/fcUtil'
  'timezone'
  'timezone/America/Detroit'
  'timezone/fr_FR'
  'helpers/I18nStubber'
  'helpers/fakeENV'
  'compiled/calendar/commonEventFactory'
], (Backbone, _, $, EditPlannerNoteDetails, fcUtil, tz, detroit, french,
    I18nStubber, fakeENV, commonEventFactory) ->

  fixtures = $('#fixtures')
  note = {
    id: "5",
    todo_date: "2017-07-22T00:00",
    title: "A To Do",
    details: "the deets",
    user_id: "1",
    course_id: null,
    workflow_state: "active",
    type: "planner_note",
    context_code: "user_1",
    all_context_codes: "user_1"
  }

  QUnit.module "EditAssignmentDetails",
    setup: ->
      @snapshot = tz.snapshot()
      @$holder = $('<table />').appendTo(document.getElementById("fixtures"))
      fakeENV.setup()

    teardown: ->
      # tick past any remaining errorBox fade-ins
      @$holder.detach()
      document.getElementById("fixtures").innerHTML = ""
      fakeENV.teardown()
      tz.restore(@snapshot)

  createView = (event = note) ->
    view = new EditPlannerNoteDetails(fixtures, event, null, null)

  commonEvent = ->
    commonEventFactory note, [{asset_string: 'user_1'}]

  test "should initialize input with start date", ->
    view = createView(commonEvent())
    equal view.$(".date_field").val(), "Sat Jul 22, 2017"

  test "should localize start date", ->
    I18nStubber.pushFrame()
    tz.changeLocale(french, 'fr_FR', 'fr')
    I18nStubber.setLocale 'fr_FR'
    I18nStubber.stub 'fr_FR',
      'date.formats.full_with_weekday': '%a %-d %b %Y %-k:%M'
      'date.formats.medium_with_weekday': '%a %-d %b %Y'
      'date.formats.medium': '%-d %b %Y'
      'date.month_names': ['août']
      'date.abbr_month_names': ['août']

    view = createView(commonEvent())
    equal view.$(".date_field").val(), "sam. 22 juil. 2017"

    I18nStubber.popFrame()

  test "requires name to save assignment note", ->
    data = Object.assign({}, note)
    data.title = ""
    view = createView(commonEvent(data))
    errors = view.validateBeforeSave(data, [])

    ok errors["title"]
    equal errors["title"].length, 1
    equal errors["title"][0]["message"], "Title is required!"

  test "requires todo_date to save note", ->
    data = Object.assign({}, note)
    data.todo_date = ""
    view = createView(commonEvent(data))
    errors = view.validateBeforeSave(data, [])

    ok errors["date"]
    equal errors["date"].length, 1
    equal errors["date"][0]["message"], "Date is required!"

  test "requires todo_date not to be in the past", ->
    data = Object.assign({}, note)
    d = new Date()
    d.setDate(d.getDate() - 1)
    data.todo_date = d
    view = createView(commonEvent(data))
    errors = view.validateBeforeSave(data, [])

    equal errors.length, 0
