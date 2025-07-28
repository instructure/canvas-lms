/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import TimeBlockListManager from '../TimeBlockListManager'
import moment from 'moment'

describe('TimeBlockListManager', () => {
  afterEach(() => {
    $('#ui-datepicker-div').empty()
  })

  it('initializes with time blocks', () => {
    const d1 = moment(new Date(2011, 12, 27, 9, 0))
    const d2 = moment(new Date(2011, 12, 27, 9, 30))
    const d3 = moment(new Date(2011, 12, 27, 10, 0))
    const d4 = moment(new Date(2011, 12, 27, 11, 30))
    const manager = new TimeBlockListManager([
      [d1, d2],
      [d3, d4],
    ])

    expect(manager.blocks).toHaveLength(2)
    expect(manager.blocks[0].start.format()).toBe(d1.format())
    expect(manager.blocks[0].end.format()).toBe(d2.format())
    expect(manager.blocks[1].start.format()).toBe(d3.format())
    expect(manager.blocks[1].end.format()).toBe(d4.format())
  })

  it('consolidates adjacent time blocks', () => {
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

    expect(manager.blocks).toHaveLength(3)
    expect(manager.blocks[0].start.format()).toBe(d1.format())
    expect(manager.blocks[0].end.format()).toBe(d2.format())
    expect(manager.blocks[1].start.format()).toBe(d3.format())
    expect(manager.blocks[1].end.format()).toBe(d4.format())
    expect(manager.blocks[2].start.format()).toBe(d4.format())
  })

  it('splits time blocks into specified intervals', () => {
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

    expect(manager.blocks).toHaveLength(5)

    const expectedTimes = [d1, d2, d2, d6, d6, d3, d4, d5, d7, d8]
    while (expectedTimes.length > 0) {
      const block = manager.blocks.shift()
      expect(block.start.format()).toBe(expectedTimes.shift().format())
      expect(block.end.format()).toBe(expectedTimes.shift().format())
    }
  })

  it('deletes unlocked time blocks', () => {
    const manager = new TimeBlockListManager()
    const d1 = moment(new Date(2011, 12, 27, 7, 0))
    const d2 = moment(new Date(2011, 12, 27, 9, 0))

    manager.add(d1, moment(new Date(2011, 12, 27, 7, 30)))
    manager.add(moment(new Date(2011, 12, 27, 8, 0)), moment(new Date(2011, 12, 27, 8, 30)))
    manager.add(d2, moment(new Date(2011, 12, 27, 9, 30)), true)

    manager.delete(3)
    expect(manager.blocks).toHaveLength(3)

    manager.delete(1)
    expect(manager.blocks).toHaveLength(2)
    expect(manager.blocks[0].start.format()).toBe(d1.format())
    expect(manager.blocks[1].start.format()).toBe(d2.format())

    // Trying to delete a locked block should not affect the list
    manager.delete(1)
    expect(manager.blocks).toHaveLength(2)
  })

  it('resets the time block list', () => {
    const manager = new TimeBlockListManager()
    manager.add(moment(new Date(2011, 12, 27, 8, 0)), moment(new Date(2011, 12, 27, 8, 30)))

    manager.reset()
    expect(manager.blocks).toHaveLength(0)
  })
})
