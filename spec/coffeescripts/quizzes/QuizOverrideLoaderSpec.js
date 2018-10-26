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

import QuizOverrideLoader from 'compiled/models/QuizOverrideLoader'

QUnit.module('QuizOverrideLoader dates selection', {
  setup() {
    this.loader = QuizOverrideLoader
    this.latestDate = '2015-04-05'
    this.middleDate = '2014-04-05'
    this.earliestDate = '2013-04-05'
    this.dates = [
      {due_at: this.latestDate, lock_at: null, unlock_at: this.middleDate},
      {due_at: this.middleDate, lock_at: null, unlock_at: this.earliestDate},
      {due_at: this.earliestDate, lock_at: null, unlock_at: this.latestDate}
    ]
  },
  teardown() {}
})

test('can select the latest date from a group', function() {
  equal(this.loader._chooseLatest(this.dates, 'due_at'), this.latestDate)
})

test('can select the earliest date from a group', function() {
  equal(this.loader._chooseEarliest(this.dates, 'unlock_at'), this.earliestDate)
})

test('handles null dates and handles empty arrays', function() {
  let dates = [{}, {}]
  equal(this.loader._chooseLatest(dates, 'due_at'), null)
  dates = []
  equal(this.loader._chooseLatest(dates, 'due_at'), null)
})

test('returns null if any argument is null', function() {
  const dates = [...this.dates, {}]
  equal(this.loader._chooseLatest(dates, 'due_at'), null)
  equal(this.loader._chooseEarliest(dates, 'due_at'), null)
})
