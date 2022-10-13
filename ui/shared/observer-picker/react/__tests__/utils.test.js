/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {parseObservedUsersList} from '../utils'

describe('parseObservedUsersList', () => {
  it('transforms attribute names', () => {
    const users = parseObservedUsersList([
      {id: '4', name: 'Student 4', avatar_url: 'https://url_here'},
      {id: '6', name: 'Student 6'},
    ])
    expect(users.length).toBe(2)
    expect(users[0].id).toBe('4')
    expect(users[0].name).toBe('Student 4')
    expect(users[0].avatarUrl).toBe('https://url_here')
    expect(users[1].id).toBe('6')
    expect(users[1].name).toBe('Student 6')
  })

  it('returns empty list if no observers passed', () => {
    const users = parseObservedUsersList([])
    expect(users.length).toBe(0)
  })
})
