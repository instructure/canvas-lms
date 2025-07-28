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

import {type Node} from '@craftjs/core'
import {getNodeIndex, getSectionLocation} from '../getNodeIndex'
import {type NodeQuery} from '../types'

describe('getNodeIndex', () => {
  let currDescendants: string[] = []

  describe('getNodeIndex', () => {
    it('returns the index of the node in the list of descendants', () => {
      const node = {id: '1', data: {parent: 'ROOT'}} as Node
      currDescendants = ['2', '1', '3']
      const query: NodeQuery = {
        node: (_id: string) => ({
          descendants: () => currDescendants,
        }),
      }
      expect(getNodeIndex(node, query)).toEqual(1)
    })
  })

  describe('getSectionLocation', () => {
    it('should return "alone" if node is the only section', () => {
      const node = {id: '1', data: {parent: 'ROOT'}} as Node
      currDescendants = ['1']
      const query: NodeQuery = {
        node: (_id: string) => ({
          descendants: () => currDescendants,
        }),
      }
      expect(getSectionLocation(node, query)).toEqual('alone')
    })

    it('should return "top" if node is the first section', () => {
      const node = {id: '1', data: {parent: 'ROOT'}} as Node
      currDescendants = ['1', '2']
      const query: NodeQuery = {
        node: (_id: string) => ({
          descendants: () => currDescendants,
        }),
      }
      expect(getSectionLocation(node, query)).toEqual('top')
    })

    it('should return "bottom" if node is the last section', () => {
      const node = {id: '1', data: {parent: 'ROOT'}} as Node
      currDescendants = ['2', '1']
      const query: NodeQuery = {
        node: (_id: string) => ({
          descendants: () => currDescendants,
        }),
      }
      expect(getSectionLocation(node, query)).toEqual('bottom')
    })

    it('should return "middle" if node is in the middle of sections', () => {
      const node = {id: '1', data: {parent: 'ROOT'}} as Node
      currDescendants = ['2', '1', '3']
      const query: NodeQuery = {
        node: (_id: string) => ({
          descendants: () => currDescendants,
        }),
      }
      expect(getSectionLocation(node, query)).toEqual('middle')
    })
  })
})
