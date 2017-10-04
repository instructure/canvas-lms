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
  'jsx/shared/helpers/dateHelper'
  'underscore'
  'timezone'
  'timezone/America/Detroit'
  'timezone/America/Juneau'
], (DateHelper, _, tz, detroit, juneau) ->

  defaultAssignment = ->
    {
      title: "assignment",
      created_at: "2015-07-06T18:35:22Z",
      due_at: "2015-07-14T18:35:22Z",
      updated_at: "2015-07-07T18:35:22Z"
    }

  QUnit.module 'DateHelper#parseDates'

  test 'returns a new object with specified dates parsed', ->
    assignment = defaultAssignment()
    datesToParse = ['created_at', 'due_at']
    assignment = DateHelper.parseDates(assignment, datesToParse)

    ok _.isDate(assignment.created_at)
    ok _.isDate(assignment.due_at)
    notOk _.isDate(assignment.updated_at)

  test 'gracefully handles null values', ->
    assignment = defaultAssignment()
    assignment.due_at = null
    datesToParse = ['created_at', 'due_at']
    assignment = DateHelper.parseDates(assignment, datesToParse)

    ok _.isDate(assignment.created_at)
    ok _.isNull(assignment.due_at)

  test 'gracefully handles undefined values', ->
    assignment = defaultAssignment()
    datesToParse = ['created_at', 'undefined_due_at']
    assignment = DateHelper.parseDates(assignment, datesToParse)

    ok _.isDate(assignment.created_at)
    ok _.isUndefined(assignment.undefined_due_at)

  QUnit.module 'DateHelper#formatDatetimeForDisplay',
    setup: ->
      @snapshot = tz.snapshot()
    teardown: ->
      tz.restore(@snapshot)

  test 'formats the date for display, adjusted for the timezone', ->
    assignment = defaultAssignment()
    tz.changeZone(detroit, 'America/Detroit')
    formattedDate = DateHelper.formatDatetimeForDisplay(assignment.due_at)
    equal formattedDate, "Jul 14, 2015 at 2:35pm"

    tz.changeZone(juneau, 'America/Juneau')
    formattedDate = DateHelper.formatDatetimeForDisplay(assignment.due_at)
    equal formattedDate, "Jul 14, 2015 at 10:35am"

  test "by default, includes the year if it matches the current year", ->
    now = new Date()
    year = now.getFullYear()
    formattedDate = DateHelper.formatDatetimeForDisplay(now)
    includesYear = new RegExp(", #{year}")
    strictEqual(includesYear.test(formattedDate), true)

  test "can specify 'short' format which excludes the year if it matches the current year", ->
    now = new Date()
    year = now.getFullYear()
    formattedDate = DateHelper.formatDatetimeForDisplay(now, "short")
    includesYear = new RegExp(", #{year}")
    strictEqual(includesYear.test(formattedDate), false)

  QUnit.module 'DateHelper#formatDateForDisplay',
    setup: ->
      @snapshot = tz.snapshot()
    teardown: ->
      tz.restore(@snapshot)

  test 'formats the date for display, adjusted for the timezone, excluding the time', ->
    assignment = defaultAssignment()
    tz.changeZone(detroit, 'America/Detroit')
    formattedDate = DateHelper.formatDateForDisplay(assignment.due_at)
    equal formattedDate, "Jul 14, 2015"

    tz.changeZone(juneau, 'America/Juneau')
    formattedDate = DateHelper.formatDateForDisplay(assignment.due_at)
    equal formattedDate, "Jul 14, 2015"

  QUnit.module 'DateHelper#isMidnight',
    setup: ->
      @snapshot = tz.snapshot()
    teardown: ->
      tz.restore(@snapshot)

  test 'returns true if the time is midnight, adjusted for the timezone', ->
    date = "2015-07-14T04:00:00Z"
    tz.changeZone(detroit, 'America/Detroit')
    ok DateHelper.isMidnight(date)

    tz.changeZone(juneau, 'America/Juneau')
    notOk DateHelper.isMidnight(date)
