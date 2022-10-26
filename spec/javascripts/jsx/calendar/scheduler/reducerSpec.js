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

import reducer from 'ui/features/calendar/react/scheduler/reducer'

QUnit.module('Scheduler Reducer')

test('sets inFindAppointmentMode on SET_FIND_APPOINTMENT_MODE', () => {
  const initialState = {
    inFindAppointmentMode: false,
    setCourse: {},
  }

  const newState = reducer(initialState, {
    type: 'SET_FIND_APPOINTMENT_MODE',
    payload: true,
  })

  ok(newState.inFindAppointmentMode)
})

test('sets selectedCourse on SET_COURSE', () => {
  const initialState = {
    inFindAppointmentMode: false,
    selectedCourse: null,
  }

  const newState = reducer(initialState, {
    type: 'SET_COURSE',
    payload: {id: 1, name: 'blah'},
  })

  ok(newState.selectedCourse)
})
