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
import fcUtil from 'compiled/util/fcUtil'
import TimeBlockList from 'compiled/calendar/TimeBlockList'
import TimeBlockRow from 'compiled/calendar/TimeBlockRow'
import tz from 'timezone'
import detroit from 'timezone/America/Detroit'

const nextYear = new Date().getFullYear() + 1
const unfudged_start = tz.parse(`${nextYear}-02-03T12:32:00Z`)
const unfudged_end = tz.parse(`${nextYear}-02-03T17:32:00Z`)

QUnit.module('TimeBlockRow', {
  setup() {
    this.snapshot = tz.snapshot()
    tz.changeZone(detroit, 'America/Detroit')
    this.start = fcUtil.wrap(unfudged_start)
    this.end = fcUtil.wrap(unfudged_end)
    this.$holder = $('<table />').appendTo(document.getElementById('fixtures'))
    this.timeBlockList = new TimeBlockList(this.$holder)

    // fakeTimer'd because the tests with failed validations add an error box
    // that is faded in. if we don't tick past the fade-in, other unrelated
    // tests that use fake timers fail.
    this.clock = sinon.useFakeTimers(new Date().valueOf())
  },

  teardown() {
    // tick past any remaining errorBox fade-ins
    this.clock.tick(250)
    this.clock.restore()
    this.$holder.detach()
    $('#fixtures').empty()
    $('.ui-tooltip').remove()
    $('.error_box').remove()
    tz.restore(this.snapshot)
  }
})

test('should init properly', function() {
  const me = new TimeBlockRow(this.timeBlockList, {start: this.start, end: this.end})
  // make sure the <input> `value`s are right
  equal(me.$date.val().trim(), tz.format(unfudged_start, 'date.formats.medium_with_weekday'))
  equal(me.$start_time.val().trim(), tz.format(unfudged_start, 'time.formats.tiny'))
  equal(me.$end_time.val().trim(), tz.format(unfudged_end, 'time.formats.tiny'))
})

test('delete link', function() {
  const me = this.timeBlockList.addRow({start: this.start, end: this.end})
  ok(this.timeBlockList.rows.includes(me), 'make sure I am in the timeBlockList to start out with')
  me.$row.find('.delete-block-link').click()

  ok(!this.timeBlockList.rows.includes(me))
  ok(!me.$row[0].parentElement, 'make sure I am no longer on the page')
})

test('validate: fields must be individually valid', function() {
  const me = new TimeBlockRow(this.timeBlockList)
  me.$date.val('invalid').change()
  ok(!me.validate())

  me.$date.data('instance').setDate(this.start)
  me.$start_time.val('invalid').change()
  ok(!me.validate())

  me.$start_time.data('instance').setDate(this.start)
  me.$end_time.val('invalid').change()
  ok(!me.validate())
})

test('validate: with good data', function() {
  const me = new TimeBlockRow(this.timeBlockList, {start: this.start, end: this.end})
  ok(me.validate(), 'whole row validates if has good info')
})

test('validate: date in past', function() {
  const me = new TimeBlockRow(this.timeBlockList, {start: this.start, end: this.end})
  me.$date.val('1/1/2000').change()
  ok(!me.validate())
  ok(me.$end_time.hasClass('error'), 'has error class')
  ok(me.$end_time.data('associated_error_box').is(':visible'), 'error box is visible')
})

test('validate: just time in past', function() {
  const fudgedMidnight = fcUtil
    .now()
    .minutes(0)
    .hours(0)
  const fudgedEnd = fcUtil.clone(fudgedMidnight)
  fudgedEnd.minutes(1)

  const me = new TimeBlockRow(this.timeBlockList, {start: fudgedMidnight, end: fudgedEnd})
  ok(!me.validate(), 'not valid if time in past')
  ok(me.$end_time.hasClass('error'), 'has error class')
  ok(me.$end_time.data('associated_error_box').is(':visible'), 'error box is visible')
})

test('validate: end before start', function() {
  const me = new TimeBlockRow(this.timeBlockList, {start: this.end, end: this.start})
  ok(!me.validate())
  ok(me.$start_time.hasClass('error'), 'has error class')
  ok(me.$start_time.data('associated_error_box').is(':visible'), 'error box is visible')
})

test('valid if whole row is blank', function() {
  const me = new TimeBlockRow(this.timeBlockList)
  ok(me.validate())
})

test('valid if incomplete', function() {
  const me = new TimeBlockRow(this.timeBlockList, {start: this.start, end: null})
  ok(me.validate())
})

test('getData', function() {
  const me = new TimeBlockRow(this.timeBlockList, {start: this.start, end: this.end})
  me.validate()
  equal(+me.getData()[0], +this.start)
  equal(+me.getData()[1], +this.end)
  equal(+me.getData()[2], false)
})

test('incomplete: false if whole row blank', function() {
  const me = new TimeBlockRow(this.timeBlockList)
  ok(!me.incomplete())
})

test('incomplete: false if whole row populated', function() {
  const me = new TimeBlockRow(this.timeBlockList, {start: this.start, end: this.end})
  ok(!me.incomplete())
})

test('incomplete: true if only one field blank', function() {
  const me = new TimeBlockRow(this.timeBlockList, {start: this.start, end: null})
  ok(me.incomplete())
})
