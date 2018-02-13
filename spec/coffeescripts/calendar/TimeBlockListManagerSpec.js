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
import TimeBlockListManager from 'compiled/calendar/TimeBlockListManager'
import moment from 'moment'

QUnit.module('TimeBlockListManager', {
  setup() {},
  teardown() {
    $('#ui-datepicker-div').empty()
  }
})

test('constructor', () => {
  const d1 = moment(new Date(2011, 12, 27, 9, 0))
  const d2 = moment(new Date(2011, 12, 27, 9, 30))
  const d3 = moment(new Date(2011, 12, 27, 10, 0))
  const d4 = moment(new Date(2011, 12, 27, 11, 30))
  const manager = new TimeBlockListManager([[d1, d2], [d3, d4]])
  equal(manager.blocks.length, 2)
  equal(manager.blocks[0].start.format(), d1.format())
  equal(manager.blocks[0].end.format(), d2.format())
  equal(manager.blocks[1].start.format(), d3.format())
  equal(manager.blocks[1].end.format(), d4.format())
})

test('consolidate', () => {
  const manager = new TimeBlockListManager()
  const d1 = moment(new Date(2011, 12, 27, 9, 0))
  const d2 = moment(new Date(2011, 12, 27, 9, 30))
  const d3 = moment(new Date(2011, 12, 27, 10, 0))
  const d4 = moment(new Date(2011, 12, 27, 11, 30))
  manager.add(d1, d2)
  manager.add(d3, moment(new Date(2011, 12, 27, 10, 30)))
  manager.add(new Date(2011, 12, 27, 10, 30), moment(new Date(2011, 12, 27, 11, 0)))
  manager.add(new Date(2011, 12, 27, 11, 0), d4)
  manager.add(d4, moment(new Date(2011, 12, 27, 12, 30)), true)
  manager.consolidate()
  equal(manager.blocks.length, 3)
  equal(manager.blocks[0].start.format(), d1.format())
  equal(manager.blocks[0].end.format(), d2.format())
  equal(manager.blocks[1].start.format(), d3.format())
  equal(manager.blocks[1].end.format(), d4.format())
  equal(manager.blocks[2].start.format(), d4.format())
})

test('split', () => {
  const manager = new TimeBlockListManager()
  const d1 = moment(new Date(2011, 12, 27, 9, 0))
  const d2 = moment(new Date(2011, 12, 27, 9, 30))
  const d3 = moment(new Date(2011, 12, 27, 10, 30))
  const d4 = moment(new Date(2011, 12, 27, 11, 0))
  const d5 = moment(new Date(2011, 12, 27, 11, 25))
  const d6 = moment(new Date(2011, 12, 27, 10, 0))
  const d7 = moment(new Date(2011, 12, 27, 12, 0))
  const d8 = moment(new Date(2011, 12, 27, 15, 0))
  manager.add(d1, d2)
  manager.add(d2, d3)
  manager.add(d4, d5)
  manager.add(d7, d8, true)
  manager.split(30)
  equal(manager.blocks.length, 5)
  const expectedTimes = [d1, d2, d2, d6, d6, d3, d4, d5, d7, d8]
  return (() => {
    const result = []
    while (expectedTimes.length > 0) {
      const block = manager.blocks.shift()
      equal(block.start.format(), expectedTimes.shift().format())
      result.push(equal(block.end.format(), expectedTimes.shift().format()))
    }
    return result
  })()
})

test('delete', () => {
  const manager = new TimeBlockListManager()
  const d1 = moment(new Date(2011, 12, 27, 7, 0))
  const d2 = moment(new Date(2011, 12, 27, 9, 0))
  manager.add(d1, moment(new Date(2011, 12, 27, 7, 30)))
  manager.add(moment(new Date(2011, 12, 27, 8, 0)), moment(new Date(2011, 12, 27, 8, 30)))
  manager.add(d2, moment(new Date(2011, 12, 27, 9, 30)), true)
  manager.delete(3)
  equal(manager.blocks.length, 3)
  manager.delete(1)
  equal(manager.blocks.length, 2)
  equal(manager.blocks[0].start.format(), d1.format())
  equal(manager.blocks[1].start.format(), d2.format())
  manager.delete(1)
  equal(manager.blocks.length, 2)
})

test('reset', () => {
  const manager = new TimeBlockListManager()
  manager.add(moment(new Date(2011, 12, 27, 8, 0)), moment(new Date(2011, 12, 27, 8, 30)))
  manager.reset()
  equal(manager.blocks.length, 0)
})
