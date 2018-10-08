/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import Actions from 'jsx/calendar/scheduler/actions'

QUnit.module('Scheduler Actions')

test('setFindAppointmentMode returns the proper action', () => {
  const actual = Actions.actions.setFindAppointmentMode(true)
  const expected = {
    type: 'SET_FIND_APPOINTMENT_MODE',
    payload: true
  }

  deepEqual(actual, expected)
})

test('setCourse returns the proper action', () => {
  const actual = Actions.actions.setCourse({id: 4, name: 'blah'})
  const expected = {
    type: 'SET_COURSE',
    payload: {id: 4, name: 'blah'}
  }

  deepEqual(actual, expected)
})
