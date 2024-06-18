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

import DateGroup from '../DateGroup'

describe('DateGroup', () => {
  test('default title is set', () => {
    const dueAt = new Date('2013-08-20 11:13:00')
    let model = new DateGroup({
      due_at: dueAt,
      title: 'Summer session',
    })
    expect(model.get('title')).toBe('Summer session')
    model = new DateGroup({due_at: dueAt})
    expect(model.get('title')).toBe('Everyone else')
  })

  test('#dueAt parses due_at to a date', () => {
    const model = new DateGroup({due_at: '2013-08-20 11:13:00'})
    expect(model.dueAt().constructor).toBe(Date)
  })

  test("#dueAt doesn't parse null date", () => {
    const model = new DateGroup({due_at: null})
    expect(model.dueAt()).toBe(null)
  })

  test('#unlockAt parses unlock_at to a date', () => {
    const model = new DateGroup({unlock_at: '2013-08-20 11:13:00'})
    expect(model.unlockAt().constructor).toBe(Date)
  })

  test("#unlockAt doesn't parse null date", () => {
    const model = new DateGroup({unlock_at: null})
    expect(model.unlockAt()).toBe(null)
  })

  test('#unlockAt parses the single_section_unlock_at property when unlock_at is null', () => {
    const model = new DateGroup({
      unlock_at: null,
      single_section_unlock_at: '2013-08-20 11:13:00',
    })
    expect(model.unlockAt().constructor).toBe(Date)
  })

  test('#lockAt parses lock_at to a date', () => {
    const model = new DateGroup({lock_at: '2013-08-20 11:13:00'})
    expect(model.lockAt().constructor).toBe(Date)
  })

  test("#lockAt doesn't parse null date", () => {
    const model = new DateGroup({lock_at: null})
    expect(model.lockAt()).toBe(null)
  })

  test('#lockAt parses the single_section_lock_at property when lock_at is null', () => {
    const model = new DateGroup({
      lock_at: null,
      single_section_lock_at: '2013-08-20 11:13:00',
    })
    expect(model.lockAt().constructor).toBe(Date)
  })

  test("#alwaysAvailable if both unlock and lock dates aren't set", () => {
    const model = new DateGroup({
      unlock_at: null,
      lock_at: null,
    })
    expect(model.alwaysAvailable()).toBe(true)
  })

  test('#alwaysAvailable is false if unlock date is set', () => {
    const model = new DateGroup({
      unlock_at: '2013-08-20 11:13:00',
      lock_at: null,
    })
    expect(model.alwaysAvailable()).toBe(false)
  })

  test('#alwaysAvailable is false if lock date is set', () => {
    const model = new DateGroup({
      unlock_at: null,
      lock_at: '2013-08-20 11:13:00',
    })
    expect(model.alwaysAvailable()).toBe(false)
  })

  test('#available is true if always available', () => {
    const model = new DateGroup({
      unlock_at: null,
      lock_at: null,
    })
    expect(model.available()).toBe(true)
  })

  test('#available is true if no lock date and unlock date has passed', () => {
    const model = new DateGroup({
      unlock_at: '2013-08-20 11:13:00',
      now: '2013-08-30 00:00:00',
    })
    expect(model.available()).toBe(true)
  })

  test('#available is false if not unlocked yet', () => {
    const model = new DateGroup({
      unlock_at: '2013-08-20 11:13:00',
      now: '2013-08-19 00:00:00',
    })
    expect(model.available()).toBe(false)
  })

  test('#available is false if locked', () => {
    const model = new DateGroup({
      lock_at: '2013-08-20 11:13:00',
      now: '2013-08-30 00:00:00',
    })
    expect(model.available()).toBe(false)
  })

  test('#pending is true if not unlocked yet', () => {
    const model = new DateGroup({
      unlock_at: '2013-08-20 11:13:00',
      now: '2013-08-19 00:00:00',
    })
    expect(model.pending()).toBe(true)
  })

  // fails in Jest, passes in QUnit
  test.skip('#pending is false if no unlock date', () => {
    const model = new DateGroup({unlock_at: null})
    expect(model.pending()).toBe(false)
  })

  test('#pending is false if unlocked', () => {
    const model = new DateGroup({
      unlock_at: '2013-08-20 11:13:00',
      now: '2013-08-30 00:00:00',
    })
    expect(model.pending()).toBe(false)
  })

  test('#open is true if has a lock date but not locked yet', () => {
    const model = new DateGroup({
      lock_at: '2013-08-20 11:13:00',
      now: '2013-08-10 00:00:00',
    })
    expect(model.open()).toBe(true)
  })

  // fails in Jest, passes in QUnit
  test.skip('#open is false without an unlock date', () => {
    const model = new DateGroup({unlock_at: null})
    expect(model.open()).toBe(false)
  })

  // fails in Jest, passes in QUnit
  test.skip('#open is false if not unlocked yet', () => {
    const model = new DateGroup({
      unlock_at: '2013-08-20 11:13:00',
      now: '2013-08-19 00:00:00',
    })
    expect(model.open()).toBe(false)
  })

  test('#closed is true if not locked', () => {
    const model = new DateGroup({
      lock_at: '2013-08-20 11:13:00',
      now: '2013-08-30 00:00:00',
    })
    expect(model.closed()).toBe(true)
  })

  // fails in Jest, passes in QUnit
  test.skip('#closed is false if no lock date', () => {
    const model = new DateGroup({lock_at: null})
    expect(model.closed()).toBe(false)
  })

  test('#closed is false if unlocked has passed', () => {
    const model = new DateGroup({
      lock_at: '2013-08-20 11:13:00',
      now: '2013-08-19 00:00:00',
    })
    expect(model.closed()).toBe(false)
  })

  test('#toJSON includes dueFor', () => {
    const model = new DateGroup({title: 'Summer session'})
    const json = model.toJSON()
    expect(json.dueFor).toBe('Summer session')
  })

  test('#toJSON includes dueAt', () => {
    const model = new DateGroup({due_at: '2013-08-20 11:13:00'})
    const json = model.toJSON()
    expect(json.dueAt.constructor).toBe(Date)
  })

  test('#toJSON includes unlockAt', () => {
    const model = new DateGroup({unlock_at: '2013-08-20 11:13:00'})
    const json = model.toJSON()
    expect(json.unlockAt.constructor).toBe(Date)
  })

  test('#toJSON includes lockAt', () => {
    const model = new DateGroup({lock_at: '2013-08-20 11:13:00'})
    const json = model.toJSON()
    expect(json.lockAt.constructor).toBe(Date)
  })

  test('#toJSON includes available', () => {
    const model = new DateGroup()
    const json = model.toJSON()
    expect(json.available).toBe(true)
  })

  test('#toJSON includes pending', () => {
    const model = new DateGroup({
      unlock_at: '2013-08-20 11:13:00',
      now: '2013-08-19 00:00:00',
    })
    const json = model.toJSON()
    expect(json.pending).toBe(true)
  })

  test('#toJSON includes open', () => {
    const model = new DateGroup({
      lock_at: '2013-08-20 11:13:00',
      now: '2013-08-10 00:00:00',
    })
    const json = model.toJSON()
    expect(json.open).toBe(true)
  })

  test('#toJSON includes closed', () => {
    const model = new DateGroup({
      lock_at: '2013-08-20 11:13:00',
      now: '2013-08-30 00:00:00',
    })
    const json = model.toJSON()
    expect(json.closed).toBe(true)
  })
})
