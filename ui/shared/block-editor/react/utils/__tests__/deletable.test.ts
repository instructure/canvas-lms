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

import {isLastChild, isNthChild} from '../deletable'

let mockDescendants: any[] = []

const query = {
  node: jest.fn((nodeId: string) => {
    if (nodeId === 'parent') {
      return {
        descendants: jest.fn().mockReturnValue(mockDescendants),
      }
    }
    return {
      get: jest.fn(() => {
        return {
          data: {
            parent: 'parent',
          },
        }
      }),
    }
  }),
}

describe('deletable', () => {
  describe('isNthChild', () => {
    it('returns false if the node is the not nth child of its parent', () => {
      mockDescendants = ['a', 'b', 'c']
      expect(isNthChild('nodeId', query, 2)).toBe(false)
    })

    it('returns true if the node is the nth child of its parent', () => {
      mockDescendants = ['a', 'b', 'c']
      expect(isNthChild('nodeId', query, 3)).toBe(true)
    })
  })

  describe('isLastChild', () => {
    it('returns true if the node is the not last child of its parent', () => {
      mockDescendants = ['a', 'b']
      expect(isLastChild('nodeId', query)).toBe(false)
    })

    it('returns false if the node is the last child of its parent', () => {
      mockDescendants = ['a']
      expect(isLastChild('nodeId', query)).toBe(true)
    })

    it('returns false if the node has no parent', () => {
      const query2 = {
        node: jest.fn().mockReturnValue({
          get: jest.fn().mockReturnValue({
            data: {},
          }),
        }),
      }
      expect(isLastChild('nodeId', query2)).toBe(false)
    })
  })
})
