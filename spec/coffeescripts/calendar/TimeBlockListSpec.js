/*
 * Copyright (C) 2012 - present Instructure, Inc.
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
import TimeBlockList from 'compiled/calendar/TimeBlockList'
import moment from 'moment'
import fcUtil from 'compiled/util/fcUtil'

QUnit.module('TimeBlockList', {
  setup() {
    const wrappedDate = str => $.fullCalendar.moment(new Date(str))

    this.$holder = $('<table>').appendTo('#fixtures')
    this.$splitter = $('<a>').appendTo('#fixtures')
    // make all of these dates in next year to gaurentee the are in the future
    const nextYear = new Date().getFullYear() + 1
    this.blocks = [
      [wrappedDate(`2/3/${nextYear} 5:32`), wrappedDate(`2/3/${nextYear} 10:32`)],
      // a locked one
      [wrappedDate(`2/3/${nextYear} 11:15`), wrappedDate(`2/3/${nextYear} 15:01`), true],
      [wrappedDate(`2/3/${nextYear} 16:00`), wrappedDate(`2/3/${nextYear} 19:00`)]
    ]
    this.blankRow = {date: fcUtil.wrap(new Date(2017, 2, 3))}
    this.me = new TimeBlockList(this.$holder, this.$splitter, this.blocks, this.blankRow)
  },

  teardown() {
    this.$holder.detach()
    this.$splitter.detach()
    $('#fixtures').empty()
    $('.ui-tooltip').remove()
  }
})

test('should init properly', function() {
  equal(this.me.rows.length, 3 + 1, 'three rows + 1 blank')
})

test('should not include locked or blank rows in .blocks()', function() {
  deepEqual(this.me.blocks(), [this.blocks[0], this.blocks[2]])
})

test('should not render custom date in blank row if more than one time block already', function() {
  equal(this.me.rows[3].$date.val(), '')
})

test('should handle intialization of locked / unlocked rows', function() {
  ok(!this.me.rows[0].locked, 'first row should not be locked')
  ok(this.me.rows[1].locked, 'second row should be locked')
})

test('should remove rows correctly', function() {
  for (const row of this.me.rows) {
  // get rid of every row
    row.remove()
    ok(!this.me.rows.includes(row))
  }

  // make sure there is still a blank row if we got rid of everything
  ok(this.me.rows.length, 1)
  ok(this.me.rows[0].blank())
})

test('should add rows correctly', function() {
  const rowsBefore = this.me.rows.length
  const data = [Date.parse('next tuesday at 7pm'), Date.parse('next tuesday at 8pm')]
  const row = this.me.addRow(data)
  equal(this.me.rows.length, rowsBefore + 1)
  ok($.contains(this.me.element, row.$row), 'make sure the element got appended to my <tbody>')
})

test('should validate if all rows are valid and complete or blank', function() {
  ok(this.me.validate(), 'should validate')
})

test('should not not validate if all rows are not valid', function() {
  const row = this.me.addRow()
  row.$date.val('asdfasdf').change()
  ok(!this.me.validate(), 'should not validate')
})

test('should not validate if a row is incomplete', function() {
  const row = this.me.addRow()
  row.$start_time.val('7pm').change()
  ok(!this.me.validate(), 'should not validate')
})

test('should still validate if a row is fully blank', function() {
  const row = this.me.addRow()
  ok(this.me.validate(), 'should validate')
})

test('should alert when invalid', function() {
  const row = this.me.addRow()
  row.$date.val('asdfasdf').change()
  const spy = this.spy(window, 'alert')
  this.me.validate()
  ok(spy.called, 'should `alert` a message')
})

test('should split correctly', function() {
  this.me.rows[2].remove()
  this.me.split('30')
  equal(this.me.rows.length, 12)
  equal(this.me.blocks().length, 10)
})

QUnit.module('TimeBlockList with no time blocks', {
  setup() {
    const wrappedDate = str => moment(new Date(str))

    this.$holder = $('<table>').appendTo('#fixtures')
    this.$splitter = $('<a>').appendTo('#fixtures')
    this.blocks = []
    this.blankRow = {date: fcUtil.wrap(new Date(2050, 2, 3))}
    this.me = new TimeBlockList(this.$holder, this.$splitter, this.blocks, this.blankRow)
  },
  teardown() {
    this.$holder.detach()
    this.$splitter.detach()
    $('#fixtures').empty()
    $('.ui-tooltip').remove()
  }
})

test('should render custom date in blank row if provided', function() {
  equal(this.me.rows[0].$date.val(), 'Thu Mar 3, 2050')
})
