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

import actions from '../actions'
import reducer from '../reducer'

interface Assignment {
  name: string
  type: string
  points: number
  due_date: string
}

interface Option {
  assignments: Assignment[]
}

interface Action {
  type: string
  payload?: unknown
}

describe('Choose Mastery Path Reducer', () => {
  const reduce = (action: Action, state = {}) => reducer(state as any, action)

  test('sets error', () => {
    const newState = reduce(actions.setError('ERROR'))
    expect(newState.error).toBe('ERROR')
  })

  test('sets options', () => {
    const options: Option[] = [
      {
        assignments: [
          {
            name: 'Ch 2 Quiz',
            type: 'quiz',
            points: 10,
            due_date: 'Aug 20',
          },
        ],
      },
    ]
    const newState = reduce(actions.setOptions(options))
    expect(newState.options).toEqual(options)
  })

  test('select option', () => {
    const newState = reduce({type: actions.SELECT_OPTION, payload: 1})
    expect(newState.selectedOption).toBe(1)
  })
})
