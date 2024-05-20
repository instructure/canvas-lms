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
import type {CoursePace} from '../../types'
import type {BlackoutDate} from '../../shared/types'
import {
  getBlackoutDateChanges,
  getPaceName,
  isNewPace,
  mergeAssignmentsAndBlackoutDates,
} from '../course_paces'
import {DEFAULT_STORE_STATE, SECTION_PACE, STUDENT_PACE} from '../../__tests__/fixtures'

const newbod1: BlackoutDate = {
  temp_id: 'tmp1',
  event_title: 'new one',
  start_date: moment(),
  end_date: moment(),
}
const oldbod1: BlackoutDate = {
  id: '1',
  event_title: 'old one',
  start_date: moment(),
  end_date: moment(),
}
const oldbod2: BlackoutDate = {
  id: '2',
  event_title: 'old two',
  start_date: moment(),
  end_date: moment(),
}

describe('course_paces reducer', () => {
  describe('getBlackoutDateChanges', () => {
    it('finds the first blackout date', () => {
      // because this was the source of a hard to find bug
      const changes = getBlackoutDateChanges([], [newbod1])
      expect(changes.length).toEqual(1)
      expect(changes[0].oldValue).toBeNull()
      expect(changes[0].newValue).toBe(newbod1)
    })

    it('finds newly added and deleted dates', () => {
      const changes = getBlackoutDateChanges([oldbod1, oldbod2], [oldbod1, newbod1])
      expect(changes.length).toEqual(2)
      // added
      expect(changes[0].oldValue).toBeNull()
      expect(changes[0].newValue).toBe(newbod1)
      // deleted
      expect(changes[1].oldValue).toBe(oldbod2)
      expect(changes[1].newValue).toBeNull()
    })
  })

  describe('isNewPace', () => {
    it('is new if it has no id and is not a student pace', () => {
      // @ts-expect-error
      expect(isNewPace({coursePace: {id: undefined, context_type: 'Course'}})).toBe(true)
    })

    it('is not new if it has an id', () => {
      // @ts-expect-error
      expect(isNewPace({coursePace: {id: '1'}})).toBe(false)
    })

    it('is not new if it is a student pace', () => {
      // because we don't have student paces in the db yet
      // the api always returns an unsaved pace with no id
      // but we need it for the start_date to show the user's
      // assignment due dates in their pace
      expect(
        // @ts-expect-error
        isNewPace({coursePace: {id: undefined, context_type: 'Enrollment'}})
      ).toBe(false)
    })

    describe('with course paces for students', () => {
      beforeAll(() => {
        window.ENV.FEATURES ||= {}
        window.ENV.FEATURES.course_paces_for_students = true
      })

      it('is new if it is a student pace', () => {
        expect(
          // @ts-expect-error
          isNewPace({coursePace: {id: undefined, context_type: 'Enrollment'}})
        ).toBe(true)
      })
    })
  })

  describe('mergeAssignmentsAndBlackoutDates', () => {
    it('discards blackout dates before the pace start', () => {
      const thePace = {
        start_date: '2022-04-01T12:00:00',
        modules: [{items: [{module_item_id: '1'}]}],
      } as CoursePace
      const dueDates = {1: '2022-05-01T12:00:00-06:00'}
      const blackoutDates = [
        {
          id: '100',
          start_date: moment('2022-01-01'),
          end_date: moment('2022-01-01'),
        } as BlackoutDate,
      ]

      const result = mergeAssignmentsAndBlackoutDates(thePace, dueDates, blackoutDates)
      expect(result[0].itemsWithDates.length).toBe(1)
      expect(result[0].itemsWithDates[0].type).toEqual('assignment')
      expect(result[0].itemsWithDates[0].module_item_id).toEqual('1')
    })

    it('discards blackout dates after pace end', () => {
      const thePace = {
        start_date: '2022-04-01T12:00:00',
        end_date: '2022-05-31T12:00:00',
        modules: [{items: [{module_item_id: '1'}]}],
      } as CoursePace
      const dueDates = {1: '2022-05-01T12:00:00-06:00'}
      const blackoutDates = [
        {
          id: '100',
          start_date: moment('2022-06-01'),
          end_date: moment('2022-06-01'),
        } as BlackoutDate,
      ]

      const result = mergeAssignmentsAndBlackoutDates(thePace, dueDates, blackoutDates)

      expect(result[0].itemsWithDates.length).toBe(1)
      expect(result[0].itemsWithDates[0].type).toEqual('assignment')
      expect(result[0].itemsWithDates[0].module_item_id).toEqual('1')
    })

    it('discards blackout dates after the last due date if pace has no end date', () => {
      const thePace = {
        start_date: '2022-04-01T12:00:00',
        modules: [{items: [{module_item_id: '1'}]}],
      } as CoursePace
      const dueDates = {1: '2022-05-01T12:00:00-06:00'}
      const blackoutDates = [
        {
          id: '100',
          start_date: moment('2022-04-15'),
          end_date: moment('2022-04-15'),
        } as BlackoutDate,
        {
          id: '101',
          start_date: moment('2022-06-01'),
          end_date: moment('2022-06-01'),
        } as BlackoutDate,
      ]

      const result = mergeAssignmentsAndBlackoutDates(thePace, dueDates, blackoutDates)

      expect(result[0].itemsWithDates.length).toBe(2)
      expect(result[0].itemsWithDates[0].type).toEqual('blackout_date')
      expect(result[0].itemsWithDates[0].id).toEqual('100')
      expect(result[0].itemsWithDates[1].type).toEqual('assignment')
      expect(result[0].itemsWithDates[1].module_item_id).toEqual('1')
    })

    it('inserts blackout dates into the module', () => {
      const thePace = {
        start_date: '2022-04-01T12:00:00',
        end_date: '2022-05-31T12:00:00',
        modules: [{items: [{module_item_id: '1'}, {module_item_id: '2'}]}],
      } as CoursePace
      const dueDates = {1: '2022-04-15T12:00:00-06:00', 2: '2022-05-01T12:00:00-06:00'}
      const blackoutDates = [
        {
          id: '100',
          start_date: moment('2022-04-20'),
          end_date: moment('2022-04-22'),
        } as BlackoutDate,
      ]

      const result = mergeAssignmentsAndBlackoutDates(thePace, dueDates, blackoutDates)

      expect(result[0].itemsWithDates.length).toBe(3)
      expect(result[0].itemsWithDates[0].type).toEqual('assignment')
      expect(result[0].itemsWithDates[0].module_item_id).toEqual('1')
      expect(result[0].itemsWithDates[1].type).toEqual('blackout_date')
      expect(result[0].itemsWithDates[1].id).toEqual('100')
      expect(result[0].itemsWithDates[2].type).toEqual('assignment')
      expect(result[0].itemsWithDates[2].module_item_id).toEqual('2')
    })

    it('puts blackout dates between modules into the latter one', () => {
      const thePace = {
        start_date: '2022-04-01T12:00:00',
        end_date: '2022-05-31T12:00:00',
        modules: [
          {items: [{module_item_id: '1'}, {module_item_id: '2'}]},
          {items: [{module_item_id: '3'}, {module_item_id: '4'}]},
        ],
      } as CoursePace
      const dueDates = {
        1: '2022-04-15T12:00:00-06:00',
        2: '2022-04-25T12:00:00-06:00',
        3: '2022-05-01T12:00:00-06:00',
        4: '2022-05-05T12:00:00-06:00',
      }
      const blackoutDates = [
        {
          id: '100',
          start_date: moment('2022-04-26'),
          end_date: moment('2022-04-27'),
        } as BlackoutDate,
      ]

      const result = mergeAssignmentsAndBlackoutDates(thePace, dueDates, blackoutDates)

      expect(result[0].itemsWithDates.length).toBe(2)
      expect(result[0].itemsWithDates[0].type).toEqual('assignment')
      expect(result[0].itemsWithDates[0].module_item_id).toEqual('1')
      expect(result[0].itemsWithDates[1].type).toEqual('assignment')
      expect(result[0].itemsWithDates[1].module_item_id).toEqual('2')
      expect(result[1].itemsWithDates.length).toBe(3)
      expect(result[1].itemsWithDates[0].type).toEqual('blackout_date')
      expect(result[1].itemsWithDates[0].id).toEqual('100')
      expect(result[1].itemsWithDates[1].type).toEqual('assignment')
      expect(result[1].itemsWithDates[1].module_item_id).toEqual('3')
      expect(result[1].itemsWithDates[2].type).toEqual('assignment')
      expect(result[1].itemsWithDates[2].module_item_id).toEqual('4')
    })

    it('adds any blackout dates after the last assignment to the last module', () => {
      const thePace = {
        start_date: '2022-04-01T12:00:00',
        end_date: '2022-05-31T12:00:00',
        modules: [
          {items: [{module_item_id: '1'}, {module_item_id: '2'}]},
          {items: [{module_item_id: '3'}, {module_item_id: '4'}]},
        ],
      } as CoursePace
      const dueDates = {
        1: '2022-04-15T12:00:00-06:00',
        2: '2022-04-25T12:00:00-06:00',
        3: '2022-05-01T12:00:00-06:00',
        4: '2022-05-05T12:00:00-06:00',
      }
      const blackoutDates = [
        {
          id: '100',
          start_date: moment('2022-05-26'),
          end_date: moment('2022-05-27'),
        } as BlackoutDate,
      ]

      const result = mergeAssignmentsAndBlackoutDates(thePace, dueDates, blackoutDates)

      expect(result[0].itemsWithDates.length).toBe(2)
      expect(result[0].itemsWithDates[0].type).toEqual('assignment')
      expect(result[0].itemsWithDates[0].module_item_id).toEqual('1')
      expect(result[0].itemsWithDates[1].type).toEqual('assignment')
      expect(result[0].itemsWithDates[1].module_item_id).toEqual('2')
      expect(result[1].itemsWithDates.length).toBe(3)
      expect(result[1].itemsWithDates[0].type).toEqual('assignment')
      expect(result[1].itemsWithDates[0].module_item_id).toEqual('3')
      expect(result[1].itemsWithDates[1].type).toEqual('assignment')
      expect(result[1].itemsWithDates[1].module_item_id).toEqual('4')
      expect(result[1].itemsWithDates[2].type).toEqual('blackout_date')
      expect(result[1].itemsWithDates[2].id).toEqual('100')
    })

    // seems like a silly test, but tests for a bug I had to fix
    it('works if there are no blackout dates in the 2nd module', () => {
      const thePace = {
        start_date: '2022-04-01T12:00:00',
        end_date: '2022-05-31T12:00:00',
        modules: [
          {items: [{module_item_id: '1'}, {module_item_id: '2'}]},
          {items: [{module_item_id: '3'}, {module_item_id: '4'}]},
        ],
      } as CoursePace
      const dueDates = {
        1: '2022-04-15T12:00:00-06:00',
        2: '2022-04-25T12:00:00-06:00',
        3: '2022-05-01T12:00:00-06:00',
        4: '2022-05-05T12:00:00-06:00',
      }
      const blackoutDates = [
        {
          id: '100',
          start_date: moment('2022-04-17'),
          end_date: moment('2022-04-17'),
        } as BlackoutDate,
      ]

      const result = mergeAssignmentsAndBlackoutDates(thePace, dueDates, blackoutDates)

      // first render, the blackout date is at the
      // top of the second module
      expect(result[0].itemsWithDates.length).toBe(3)
      expect(result[0].itemsWithDates[0].type).toEqual('assignment')
      expect(result[0].itemsWithDates[0].module_item_id).toEqual('1')
      expect(result[0].itemsWithDates[1].type).toEqual('blackout_date')
      expect(result[0].itemsWithDates[1].id).toEqual('100')
      expect(result[0].itemsWithDates[2].type).toEqual('assignment')
      expect(result[0].itemsWithDates[2].module_item_id).toEqual('2')

      expect(result[1].itemsWithDates.length).toBe(2)
    })
  })

  describe('getPaceName', () => {
    it('gets pace name for course pace', () => {
      expect(getPaceName(DEFAULT_STORE_STATE)).toBe('Neuromancy 300')
    })

    it('gets pace name for section pace', () => {
      expect(getPaceName({...DEFAULT_STORE_STATE, coursePace: SECTION_PACE})).toBe('Hackers')
    })

    it('gets pace name for student pace', () => {
      expect(getPaceName({...DEFAULT_STORE_STATE, coursePace: STUDENT_PACE})).toBe(
        'Henry Dorsett Case'
      )
    })
  })
})
