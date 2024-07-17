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
import 'jquery-migrate'
import TimeBlockList from '../TimeBlockList'
import fcUtil from '@canvas/calendar/jquery/fcUtil'

const ok = x => expect(x).toBeTruthy()
const equal = (x, y) => expect(x).toEqual(y)
const deepEqual = (x, y) => expect(x).toEqual(y)

let $holder
let blocks
let blankRow
let me
let $splitter
let jsdomAlert

describe('TimeBlockList', () => {
  beforeEach(() => {
    const wrappedDate = str => $.fullCalendar.moment(new Date(str))

    $holder = $('<table>').appendTo('#fixtures')
    $splitter = $('<a>').appendTo('#fixtures')
    // make all of these dates in next year to gaurentee the are in the future
    const nextYear = new Date().getFullYear() + 1
    blocks = [
      [wrappedDate(`2/3/${nextYear} 5:32`), wrappedDate(`2/3/${nextYear} 10:32`)],
      // a locked one
      [wrappedDate(`2/3/${nextYear} 11:15`), wrappedDate(`2/3/${nextYear} 15:01`), true],
      [wrappedDate(`2/3/${nextYear} 16:00`), wrappedDate(`2/3/${nextYear} 19:00`)],
    ]
    blankRow = {date: fcUtil.wrap(new Date(2017, 2, 3))}
    me = new TimeBlockList($holder, $splitter, blocks, blankRow)
    jsdomAlert = window.alert
    window.alert = () => {}
  })

  afterEach(() => {
    $holder.detach()
    $splitter.detach()
    $('#fixtures').empty()
    $('.ui-tooltip').remove()
    window.alert = jsdomAlert
  })

  test('should init properly', function () {
    equal(me.rows.length, 3 + 1, 'three rows + 1 blank')
  })

  test('should not include locked or blank rows in .blocks()', function () {
    deepEqual(me.blocks(), [blocks[0], blocks[2]])
  })

  test('should not render custom date in blank row if more than one time block already', function () {
    equal(me.rows[3].$date.val(), '')
  })

  test('should handle intialization of locked / unlocked rows', function () {
    ok(!me.rows[0].locked, 'first row should not be locked')
    ok(me.rows[1].locked, 'second row should be locked')
  })

  test('should remove rows correctly', function () {
    for (const row of me.rows) {
      // get rid of every row
      row.remove()
      ok(!me.rows.includes(row))
    }

    // make sure there is still a blank row if we got rid of everything
    ok(me.rows.length, 1)
    ok(me.rows[0].blank())
  })

  test('should validate if all rows are valid and complete or blank', function () {
    ok(me.validate(), 'should validate')
  })

  test('should not not validate if all rows are not valid', function () {
    const row = me.addRow()
    row.$date.val('asdfasdf').change()
    ok(!me.validate(), 'should not validate')
  })

  test('should not validate if a row is incomplete', function () {
    const row = me.addRow()
    row.$start_time.val('7pm').change()
    ok(!me.validate(), 'should not validate')
  })

  test('should still validate if a row is fully blank', function () {
    ok(me.validate(), 'should validate')
  })

  test('should split correctly', function () {
    me.rows[2].remove()
    me.split('30')
    equal(me.rows.length, 12)
    equal(me.blocks().length, 10)
  })
})

describe('TimeBlockList with no time blocks', () => {
  beforeEach(() => {
    $holder = $('<table>').appendTo('#fixtures')
    $splitter = $('<a>').appendTo('#fixtures')
    blocks = []
    blankRow = {date: fcUtil.wrap(new Date(2050, 2, 3))}
    me = new TimeBlockList($holder, $splitter, blocks, blankRow)
  })

  afterEach(() => {
    $holder.detach()
    $splitter.detach()
    $('#fixtures').empty()
    $('.ui-tooltip').remove()
  })

  test('should render custom date in blank row if provided', function () {
    equal(me.rows[0].$date.val(), '2050-03-03')
  })
})
