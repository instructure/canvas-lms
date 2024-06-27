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

import {actions} from '../../actions'
import reducer from '../root-reducer'

describe('Conditional Release Stats reducer', () => {
  const reduce = (action, state = {}) => {
    return reducer(state, action)
  }

  test('sets correct number of students enrolled', () => {
    const newState = reduce(actions.setEnrolled(10))
    expect(newState.enrolled).toBe(10)
  })

  test('sets the correct trigger assignment', () => {
    const newState = reduce(actions.setAssignment(2))
    expect(newState.assignment).toBe(2)
  })

  test('updates range boundaries with correct values', () => {
    const ranges = [{upper_bound: '10'}, {upper_bound: '11'}]
    const newState = reduce(actions.setScoringRanges(ranges))
    expect(newState.ranges).toEqual(ranges)
  })

  test('sets the correct errors', () => {
    const errors = ['Invalid Rule', 'Unable to Load']
    const newState = reduce(actions.setErrors(errors))
    expect(newState.errors).toEqual(errors)
  })

  test('open sidebar correctly', () => {
    const element = jest.fn()
    const newState = reduce(actions.openSidebar(element))
    expect(newState.showDetails).toBe(true)
    expect(newState.sidebarTrigger).toBe(element)
  })

  test('open sidebar on select range', () => {
    const newState = reduce(actions.selectRange(1))
    expect(newState.showDetails).toBe(true)
  })

  test('closes sidebar correctly', () => {
    const newState = reduce(actions.closeSidebar())
    expect(newState.showDetails).toBe(false)
  })

  test('closes sidebar resets selected student', () => {
    const newState = reduce(actions.closeSidebar())
    expect(newState.selectedPath.student).toBeNull()
  })

  test('selects range', () => {
    const newState = reduce(actions.selectRange(1))
    expect(newState.selectedPath.range).toBe(1)
  })

  test('selects student', () => {
    const newState = reduce({type: 'SELECT_STUDENT', payload: 1})
    expect(newState.selectedPath.student).toBe(1)
  })

  test('tests cache student', () => {
    const newState = reduce(
      actions.addStudentToCache({
        studentId: '1',
        data: {
          trigger_assignment: {
            assignment: {id: '1'},
            submission: {grade: '100'},
          },
          follow_on_assignments: [
            {
              score: 100,
              assignment: {id: '2'},
            },
          ],
        },
      })
    )
    expect(newState.studentCache).toEqual({
      1: {
        triggerAssignment: {
          assignment: {id: '1'},
          submission: {grade: '100'},
        },
        followOnAssignments: [
          {
            score: 100,
            assignment: {id: '2'},
          },
        ],
      },
    })
  })

  test('load start', () => {
    const newState = reduce(actions.loadInitialDataStart())
    expect(newState.isInitialDataLoading).toBe(true)
  })

  test('load end', () => {
    const newState = reduce(actions.loadInitialDataEnd())
    expect(newState.isInitialDataLoading).toBe(false)
  })
})
