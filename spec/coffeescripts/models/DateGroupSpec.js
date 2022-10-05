/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import Backbone from '@canvas/backbone'
import DateGroup from '@canvas/date-group/backbone/models/DateGroup'

QUnit.module('DateGroup', {
  setup() {},
})

test('default title is set', () => {
  const dueAt = new Date('2013-08-20 11:13:00')
  let model = new DateGroup({
    due_at: dueAt,
    title: 'Summer session',
  })
  equal(model.get('title'), 'Summer session')
  model = new DateGroup({due_at: dueAt})
  equal(model.get('title'), 'Everyone else')
})

test('#dueAt parses due_at to a date', () => {
  const model = new DateGroup({due_at: '2013-08-20 11:13:00'})
  equal(model.dueAt().constructor, Date)
})

test("#dueAt doesn't parse null date", () => {
  const model = new DateGroup({due_at: null})
  equal(model.dueAt(), null)
})

test('#unlockAt parses unlock_at to a date', () => {
  const model = new DateGroup({unlock_at: '2013-08-20 11:13:00'})
  equal(model.unlockAt().constructor, Date)
})

test("#unlockAt doesn't parse null date", () => {
  const model = new DateGroup({unlock_at: null})
  equal(model.unlockAt(), null)
})

test('#unlockAt parses the single_section_unlock_at property when unlock_at is null', () => {
  const model = new DateGroup({
    unlock_at: null,
    single_section_unlock_at: '2013-08-20 11:13:00',
  })
  equal(model.unlockAt().constructor, Date)
})

test('#lockAt parses lock_at to a date', () => {
  const model = new DateGroup({lock_at: '2013-08-20 11:13:00'})
  equal(model.lockAt().constructor, Date)
})

test("#lockAt doesn't parse null date", () => {
  const model = new DateGroup({lock_at: null})
  equal(model.lockAt(), null)
})

test('#lockAt parses the single_section_lock_at property when lock_at is null', () => {
  const model = new DateGroup({
    lock_at: null,
    single_section_lock_at: '2013-08-20 11:13:00',
  })
  equal(model.lockAt().constructor, Date)
})

test("#alwaysAvailable if both unlock and lock dates aren't set", () => {
  const model = new DateGroup({
    unlock_at: null,
    lock_at: null,
  })
  ok(model.alwaysAvailable())
})

test('#alwaysAvailable is false if unlock date is set', () => {
  const model = new DateGroup({
    unlock_at: '2013-08-20 11:13:00',
    lock_at: null,
  })
  ok(!model.alwaysAvailable())
})

test('#alwaysAvailable is false if lock date is set', () => {
  const model = new DateGroup({
    unlock_at: null,
    lock_at: '2013-08-20 11:13:00',
  })
  ok(!model.alwaysAvailable())
})

test('#available is true if always available', () => {
  const model = new DateGroup({
    unlock_at: null,
    lock_at: null,
  })
  ok(model.available())
})

test('#available is true if no lock date and unlock date has passed', () => {
  const model = new DateGroup({
    unlock_at: '2013-08-20 11:13:00',
    now: '2013-08-30 00:00:00',
  })
  ok(model.available())
})

test('#available is false if not unlocked yet', () => {
  const model = new DateGroup({
    unlock_at: '2013-08-20 11:13:00',
    now: '2013-08-19 00:00:00',
  })
  ok(!model.available())
})

test('#available is false if locked', () => {
  const model = new DateGroup({
    lock_at: '2013-08-20 11:13:00',
    now: '2013-08-30 00:00:00',
  })
  ok(!model.available())
})

test('#pending is true if not unlocked yet', () => {
  const model = new DateGroup({
    unlock_at: '2013-08-20 11:13:00',
    now: '2013-08-19 00:00:00',
  })
  ok(model.pending())
})

test('#pending is false if no unlock date', () => {
  const model = new DateGroup({unlock_at: null})
  ok(!model.pending())
})

test('#pending is false if unlocked', () => {
  const model = new DateGroup({
    unlock_at: '2013-08-20 11:13:00',
    now: '2013-08-30 00:00:00',
  })
  ok(!model.pending())
})

test('#open is true if has a lock date but not locked yet', () => {
  const model = new DateGroup({
    lock_at: '2013-08-20 11:13:00',
    now: '2013-08-10 00:00:00',
  })
  ok(model.open())
})

test('#open is false without an unlock date', () => {
  const model = new DateGroup({unlock_at: null})
  ok(!model.open())
})

test('#open is false if not unlocked yet', () => {
  const model = new DateGroup({
    unlock_at: '2013-08-20 11:13:00',
    now: '2013-08-19 00:00:00',
  })
  ok(!model.open())
})

test('#closed is true if not locked', () => {
  const model = new DateGroup({
    lock_at: '2013-08-20 11:13:00',
    now: '2013-08-30 00:00:00',
  })
  ok(model.closed())
})

test('#closed is false if no lock date', () => {
  const model = new DateGroup({lock_at: null})
  ok(!model.closed())
})

test('#closed is false if unlocked has passed', () => {
  const model = new DateGroup({
    lock_at: '2013-08-20 11:13:00',
    now: '2013-08-19 00:00:00',
  })
  ok(!model.closed())
})

test('#toJSON includes dueFor', () => {
  const model = new DateGroup({title: 'Summer session'})
  const json = model.toJSON()
  equal(json.dueFor, 'Summer session')
})

test('#toJSON includes dueAt', () => {
  const model = new DateGroup({due_at: '2013-08-20 11:13:00'})
  const json = model.toJSON()
  equal(json.dueAt.constructor, Date)
})

test('#toJSON includes unlockAt', () => {
  const model = new DateGroup({unlock_at: '2013-08-20 11:13:00'})
  const json = model.toJSON()
  equal(json.unlockAt.constructor, Date)
})

test('#toJSON includes lockAt', () => {
  const model = new DateGroup({lock_at: '2013-08-20 11:13:00'})
  const json = model.toJSON()
  equal(json.lockAt.constructor, Date)
})

test('#toJSON includes available', () => {
  const model = new DateGroup()
  const json = model.toJSON()
  equal(json.available, true)
})

test('#toJSON includes pending', () => {
  const model = new DateGroup({
    unlock_at: '2013-08-20 11:13:00',
    now: '2013-08-19 00:00:00',
  })
  const json = model.toJSON()
  equal(json.pending, true)
})

test('#toJSON includes open', () => {
  const model = new DateGroup({
    lock_at: '2013-08-20 11:13:00',
    now: '2013-08-10 00:00:00',
  })
  const json = model.toJSON()
  equal(json.open, true)
})

test('#toJSON includes closed', () => {
  const model = new DateGroup({
    lock_at: '2013-08-20 11:13:00',
    now: '2013-08-30 00:00:00',
  })
  const json = model.toJSON()
  equal(json.closed, true)
})
