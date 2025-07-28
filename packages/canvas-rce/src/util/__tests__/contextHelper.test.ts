/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {normalizeContainingContext} from '../contextHelper'

describe('normalizeContainingContext', () => {
  it('returns the context as is if it is valid (user)', () => {
    const context = {
      contextType: 'user',
      contextId: '1',
      userId: '2',
    }
    expect(normalizeContainingContext(context)).toEqual(context)
  })

  it('returns the context as is if it is valid (course)', () => {
    const context = {
      contextType: 'course',
      contextId: '1',
      userId: '2',
    }
    expect(normalizeContainingContext(context)).toEqual(context)
  })

  it('returns the context as is if it is valid (group)', () => {
    const context = {
      contextType: 'group',
      contextId: '1',
      userId: '2',
    }
    expect(normalizeContainingContext(context)).toEqual(context)
  })

  it('returns the context with contextType set to user if it is not valid', () => {
    const context = {
      contextType: 'invalid',
      contextId: '1',
      userId: '2',
    }
    expect(normalizeContainingContext(context)).toEqual({
      contextType: 'user',
      contextId: '2',
      userId: '2',
    })
  })
})
