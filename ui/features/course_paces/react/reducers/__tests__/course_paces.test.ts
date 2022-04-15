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
import {BlackoutDate} from '../../shared/types'
import {getBlackoutDateChanges} from '../course_paces'

const newbod1: BlackoutDate = {
  temp_id: 'tmp1',
  event_title: 'new one',
  start_date: moment(),
  end_date: moment()
}
const oldbod1: BlackoutDate = {
  id: '1',
  event_title: 'old one',
  start_date: moment(),
  end_date: moment()
}
const oldbod2: BlackoutDate = {
  id: '2',
  event_title: 'old two',
  start_date: moment(),
  end_date: moment()
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
})
