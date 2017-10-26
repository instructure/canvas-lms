#
# Copyright (C) 2016 - present Instructure, Inc.
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
  'compiled/collections/GradeChangeLoggingCollection'
  'compiled/views/accounts/admin_tools/GradeChangeLoggingContentView'
  'jquery'
  'helpers/fakeENV'
  'helpers/assertions'
], (GradeChangeLoggingCollection, GradeChangeLoggingContentView, $, fakeENV, assertions) ->
  buildEvent = (options) =>
    options ?= {}
    base =
      "id":1
      "created_at":"2016-04-20T19:27:56Z"
      "event_type":"grade_change"
      "grade_before":"10.00%"
      "grade_after":"50.00%"
      "excused_before":false
      "excused_after":false
      "graded_anonymously":false
      "version_number":30
      "links":{
        "assignment":12
        "course":2
        "student":7
        "grader":1
        "page_view":null
      }
    $.extend base, options

  excusedEvent = ->
    buildEvent
      "id":1
      "excused_before":false
      "excused_after":true

  unexcusedEvent = ->
    buildEvent
      "id":1
      "excused_before":true
      "excused_after":false

  createView = (logItems, options) ->
    options = $.extend {users: []}, options
    collection = new GradeChangeLoggingCollection(logItems)
    view = new GradeChangeLoggingContentView
      collection: collection
    view.$el.appendTo $('#fixtures')
    view.render()
    view

  QUnit.module 'GradeChangeLoggingItemView',
    setup: ->
      fakeENV.setup()
      $(document).off()

    teardown: ->
      $('#fixtures').empty()
      fakeENV.teardown()

  test 'it should be accessible', (assert) ->
    view = createView([excusedEvent()])
    done = assert.async()
    assertions.isAccessible view, done, {'a11yReport': true}

  test "initializes", ->
    view = createView([])
    ok view.collection

  test "displays 'EX' for excused submissions", ->
    view = createView([excusedEvent()])
    grade = view.$(".logitem:first-child td:nth-child(4)")
    equal grade.text().replace(/^\s+|\s+$/g, ''), "EX"

  test "displays 'EX' for previously-excused submissions", ->
    view = createView([unexcusedEvent()])
    grade = view.$(".logitem:first-child td:nth-child(3)")
    equal grade.text().replace(/^\s+|\s+$/g, ''), "EX"
