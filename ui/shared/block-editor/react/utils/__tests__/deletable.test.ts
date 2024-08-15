/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {notDeletableIfLastChild} from '../deletable'

describe('notDeletableIfLastChild', () => {
  it('returns false if the node is the last child of its parent', () => {
    const query = {
      node: jest.fn().mockReturnValue({
        get: jest.fn().mockReturnValue({
          data: {
            parent: 'parent',
          },
        }),
        descendants: jest.fn().mockReturnValue([1]),
      }),
    }
    expect(notDeletableIfLastChild('nodeId', query)).toBe(false)
  })

  it('returns true if the node is not the last child of its parent', () => {
    const query = {
      node: jest.fn().mockReturnValue({
        get: jest.fn().mockReturnValue({
          data: {
            parent: 'parent',
          },
        }),
        descendants: jest.fn().mockReturnValue([1, 2]),
      }),
    }
    expect(notDeletableIfLastChild('nodeId', query)).toBe(true)
  })

  it('returns false if the node has no parent', () => {
    const query = {
      node: jest.fn().mockReturnValue({
        get: jest.fn().mockReturnValue({
          data: {},
        }),
      }),
    }
    expect(notDeletableIfLastChild('nodeId', query)).toBe(false)
  })
})
