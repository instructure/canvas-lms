/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import moment from 'moment-timezone'
import {mergeAssignmentsAndBlackoutDates} from '../course_pace_table'
import {CoursePace, CoursePaceItemDueDates} from '../../../types'
import {BlackoutDate} from '../../../shared/types'

moment.tz.setDefault('America/Denver')

describe('course_pace_table', () => {
  describe('mergeAssignmentsAndBlackoutDates', () => {
    it('discards blackout dates before the pace start', () => {
      const thePace = {
        start_date: '2022-04-01T12:00:00',
        modules: [{items: [{module_item_id: '1'}]}]
      }
      const dueDates = {1: '2022-05-01T12:00:00-06:00'}
      const blackoutDates = [
        {id: '100', start_date: moment('2022-01-01'), end_date: moment('2022-01-01')}
      ]

      const result = mergeAssignmentsAndBlackoutDates(
        thePace as CoursePace,
        dueDates as CoursePaceItemDueDates,
        blackoutDates as BlackoutDate[]
      )
      expect(result[0].items.length).toBe(1)
      expect(result[0].items[0].type).toEqual('assignment')
      expect(result[0].items[0].module_item_id).toEqual('1')
    })

    it('discards blackout dates after pace end', () => {
      const thePace = {
        start_date: '2022-04-01T12:00:00',
        end_date: '2022-05-31T12:00:00',
        // @ts-ignore
        modules: [{items: [{module_item_id: '1'}]}]
      }
      const dueDates = {1: '2022-05-01T12:00:00-06:00'}
      const blackoutDates = [
        {id: '100', start_date: moment('2022-06-01'), end_date: moment('2022-06-01')}
      ]

      const result = mergeAssignmentsAndBlackoutDates(
        thePace as CoursePace,
        dueDates as CoursePaceItemDueDates,
        blackoutDates as BlackoutDate[]
      )

      expect(result[0].items.length).toBe(1)
      expect(result[0].items[0].type).toEqual('assignment')
      expect(result[0].items[0].module_item_id).toEqual('1')
    })

    it('discards blackout dates after the last due date if pace has no end date', () => {
      const thePace = {
        start_date: '2022-04-01T12:00:00',
        // @ts-ignore
        modules: [{items: [{module_item_id: '1'}]}]
      }
      const dueDates = {1: '2022-05-01T12:00:00-06:00'}
      const blackoutDates = [
        {id: '100', start_date: moment('2022-04-15'), end_date: moment('2022-04-15')},
        {id: '101', start_date: moment('2022-06-01'), end_date: moment('2022-06-01')}
      ]

      const result = mergeAssignmentsAndBlackoutDates(
        thePace as CoursePace,
        dueDates as CoursePaceItemDueDates,
        blackoutDates as BlackoutDate[]
      )

      expect(result[0].items.length).toBe(2)
      expect(result[0].items[0].type).toEqual('blackout_date')
      expect(result[0].items[0].id).toEqual('100')
      expect(result[0].items[1].type).toEqual('assignment')
      expect(result[0].items[1].module_item_id).toEqual('1')
    })

    it('inserts blackout dates into the module', () => {
      const thePace = {
        start_date: '2022-04-01T12:00:00',
        end_date: '2022-05-31T12:00:00',
        modules: [{items: [{module_item_id: '1'}, {module_item_id: '2'}]}]
      }
      const dueDates = {1: '2022-04-15T12:00:00-06:00', 2: '2022-05-01T12:00:00-06:00'}
      const blackoutDates = [
        {id: '100', start_date: moment('2022-04-20'), end_date: moment('2022-04-22')}
      ]

      const result = mergeAssignmentsAndBlackoutDates(
        thePace as CoursePace,
        dueDates as CoursePaceItemDueDates,
        blackoutDates as BlackoutDate[]
      )

      expect(result[0].items.length).toBe(3)
      expect(result[0].items[0].type).toEqual('assignment')
      expect(result[0].items[0].module_item_id).toEqual('1')
      expect(result[0].items[1].type).toEqual('blackout_date')
      expect(result[0].items[1].id).toEqual('100')
      expect(result[0].items[2].type).toEqual('assignment')
      expect(result[0].items[2].module_item_id).toEqual('2')
    })

    it('puts blackout dates between modules into the latter one', () => {
      const thePace = {
        start_date: '2022-04-01T12:00:00',
        end_date: '2022-05-31T12:00:00',
        modules: [
          {items: [{module_item_id: '1'}, {module_item_id: '2'}]},
          {items: [{module_item_id: '3'}, {module_item_id: '4'}]}
        ]
      }
      const dueDates = {
        1: '2022-04-15T12:00:00-06:00',
        2: '2022-04-25T12:00:00-06:00',
        3: '2022-05-01T12:00:00-06:00',
        4: '2022-05-05T12:00:00-06:00'
      }
      const blackoutDates = [
        {id: '100', start_date: moment('2022-04-26'), end_date: moment('2022-04-27')}
      ]

      const result = mergeAssignmentsAndBlackoutDates(
        thePace as CoursePace,
        dueDates as CoursePaceItemDueDates,
        blackoutDates as BlackoutDate[]
      )

      expect(result[0].items.length).toBe(2)
      expect(result[0].items[0].type).toEqual('assignment')
      expect(result[0].items[0].module_item_id).toEqual('1')
      expect(result[0].items[1].type).toEqual('assignment')
      expect(result[0].items[1].module_item_id).toEqual('2')
      expect(result[1].items.length).toBe(3)
      expect(result[1].items[0].type).toEqual('blackout_date')
      expect(result[1].items[0].id).toEqual('100')
      expect(result[1].items[1].type).toEqual('assignment')
      expect(result[1].items[1].module_item_id).toEqual('3')
      expect(result[1].items[2].type).toEqual('assignment')
      expect(result[1].items[2].module_item_id).toEqual('4')
    })

    it('adds any blackout dates after the last assignment to the last module', () => {
      const thePace = {
        start_date: '2022-04-01T12:00:00',
        end_date: '2022-05-31T12:00:00',
        modules: [
          {items: [{module_item_id: '1'}, {module_item_id: '2'}]},
          {items: [{module_item_id: '3'}, {module_item_id: '4'}]}
        ]
      }
      const dueDates = {
        1: '2022-04-15T12:00:00-06:00',
        2: '2022-04-25T12:00:00-06:00',
        3: '2022-05-01T12:00:00-06:00',
        4: '2022-05-05T12:00:00-06:00'
      }
      const blackoutDates = [
        {id: '100', start_date: moment('2022-05-26'), end_date: moment('2022-05-27')}
      ]

      const result = mergeAssignmentsAndBlackoutDates(
        thePace as CoursePace,
        dueDates as CoursePaceItemDueDates,
        blackoutDates as BlackoutDate[]
      )

      expect(result[0].items.length).toBe(2)
      expect(result[0].items[0].type).toEqual('assignment')
      expect(result[0].items[0].module_item_id).toEqual('1')
      expect(result[0].items[1].type).toEqual('assignment')
      expect(result[0].items[1].module_item_id).toEqual('2')
      expect(result[1].items.length).toBe(3)
      expect(result[1].items[0].type).toEqual('assignment')
      expect(result[1].items[0].module_item_id).toEqual('3')
      expect(result[1].items[1].type).toEqual('assignment')
      expect(result[1].items[1].module_item_id).toEqual('4')
      expect(result[1].items[2].type).toEqual('blackout_date')
      expect(result[1].items[2].id).toEqual('100')
    })

    // seems like a silly test, but tests for a bug I had to fix
    it('works if there are no blackout dates in the 2nd module', () => {
      const thePace = {
        start_date: '2022-04-01T12:00:00',
        end_date: '2022-05-31T12:00:00',
        modules: [
          {items: [{module_item_id: '1'}, {module_item_id: '2'}]},
          {items: [{module_item_id: '3'}, {module_item_id: '4'}]}
        ]
      }
      const dueDates = {
        1: '2022-04-15T12:00:00-06:00',
        2: '2022-04-25T12:00:00-06:00',
        3: '2022-05-01T12:00:00-06:00',
        4: '2022-05-05T12:00:00-06:00'
      }
      const blackoutDates = [
        {id: '100', start_date: moment('2022-04-17'), end_date: moment('2022-04-17')}
      ]

      const result = mergeAssignmentsAndBlackoutDates(
        thePace as CoursePace,
        dueDates as CoursePaceItemDueDates,
        blackoutDates as BlackoutDate[]
      )

      // first render, the blackout date is at the
      // top of the second module
      expect(result[0].items.length).toBe(3)
      expect(result[0].items[0].type).toEqual('assignment')
      expect(result[0].items[0].module_item_id).toEqual('1')
      expect(result[0].items[1].type).toEqual('blackout_date')
      expect(result[0].items[1].id).toEqual('100')
      expect(result[0].items[2].type).toEqual('assignment')
      expect(result[0].items[2].module_item_id).toEqual('2')

      expect(result[1].items.length).toBe(2)
    })
  })
})
