/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import rootReducer from '../index'

it('sets the default state for all properties empty initial state', () => {
  const newState = rootReducer({}, {type: 'FAKE_ACTION'})
  expect(newState).toMatchObject({
    courses: [],
    groups: [],
    locale: 'en',
    timeZone: 'UTC',
    days: [],
    loading: {
      isLoading: false,
    },
    firstNewActivityDate: null,
    selectedObservee: null,
  })
})

it('clones the first new activity date moment', () => {
  const initialState = rootReducer({}, {type: 'blah'})
  const mockMoment = moment()
  const nextState = rootReducer(initialState, {
    type: 'FOUND_FIRST_NEW_ACTIVITY_DATE',
    payload: mockMoment,
  })
  expect(nextState.firstNewActivityDate).not.toBe(mockMoment)
})
