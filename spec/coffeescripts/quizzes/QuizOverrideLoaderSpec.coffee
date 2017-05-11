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
  'compiled/models/QuizOverrideLoader'
], (QuizOverrideLoader) ->

  QUnit.module 'QuizOverrideLoader dates selection',
    setup: ->
      @loader = QuizOverrideLoader
      @latestDate = "2015-04-05"
      @middleDate = "2014-04-05"
      @earliestDate = "2013-04-05"

      @dates = [
        {due_at: @latestDate, lock_at: null, unlock_at: @middleDate},
        {due_at: @middleDate, lock_at: null, unlock_at: @earliestDate},
        {due_at: @earliestDate, lock_at: null, unlock_at: @latestDate}
      ]

    teardown: ->
      # noop

  test 'can select the latest date from a group', ->
    equal @loader._chooseLatest(@dates, "due_at"), @latestDate

  test 'can select the earliest date from a group', ->
    equal @loader._chooseEarliest(@dates, "unlock_at"), @earliestDate

  test 'ignores null dates and handles empty arrays', ->
    dates = [{},{}]
    equal @loader._chooseLatest(dates, "due_at"), null
    dates = []
    equal @loader._chooseLatest(dates, "due_at"), null
