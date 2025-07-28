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

import type {BlockTemplate} from '../../types'
import {
  transformTemplate,
  transform,
  transform_0_1_to_0_2,
  transform_0_2_to_0_3,
  LATEST_BLOCK_DATA_VERSION,
  type BlockEditorData,
  type BlockEditorDataTypes,
  type BlockEditorData_0_1,
  type BlockEditorData_0_2,
} from '../transformations'

const nodes = '{"ROOT":{"type":{"resolvedName":"PageBlock"}}}'

describe('transformations', () => {
  let nodes2: any, nodes3: any
  beforeAll(() => {
    nodes2 = JSON.parse(nodes)
    nodes2.foo = {
      type: {
        resolvedName: 'RCEBlock',
      },
    }
    nodes3 = JSON.parse(JSON.stringify(nodes2))
    nodes3.foo.type.resolvedName = 'RCETextBlock'
  })

  describe('transform', () => {
    it('returns the same data if the version is the latest', () => {
      const data: BlockEditorData = {
        version: LATEST_BLOCK_DATA_VERSION,
        blocks: {},
      }
      expect(transform(data)).toEqual(data)
    })

    it('transforms version 0.1 to the latest version', () => {
      const data: BlockEditorDataTypes = {
        version: '0.1',
        blocks: [{data: nodes}],
      }
      expect(transform(data)).toEqual({
        version: LATEST_BLOCK_DATA_VERSION,
        blocks: JSON.parse(nodes),
      })
    })

    describe('transform 0.1 to 0.2', () => {
      it('transforms data', () => {
        const data: BlockEditorData_0_1 = {
          version: '0.1',
          blocks: [{data: nodes}],
        }
        expect(transform_0_1_to_0_2(data)).toEqual({
          version: '0.2',
          blocks: nodes,
        })
      })
    })

    describe('transform 0.2 to 0.3', () => {
      it('transforms block data', () => {
        const data: BlockEditorData_0_2 = {
          version: '0.2',
          blocks: JSON.stringify(nodes2),
        }

        const nodes3Transformed = JSON.parse(JSON.stringify(nodes3))
        nodes3Transformed.foo.type.resolvedName = 'RCETextBlock'
        expect(transform_0_2_to_0_3(data)).toEqual({
          version: '0.3',
          blocks: nodes3Transformed,
        })
      })
    })
  })

  describe('transformTemplate', () => {
    it('does nothing if the version is the latest', () => {
      const template = {
        editor_version: LATEST_BLOCK_DATA_VERSION,
        node_tree: {},
      } as unknown as BlockTemplate
      expect(transformTemplate(template)).toEqual(template)
    })

    it('transforms version 0.2 to the latest version', () => {
      const template = {
        editor_version: '0.2',
        node_tree: {
          rootNodeId: 'ROOT',
          nodes: nodes2,
        },
      } as unknown as BlockTemplate
      expect(transformTemplate(template)).toEqual({
        editor_version: LATEST_BLOCK_DATA_VERSION,
        node_tree: {
          rootNodeId: 'ROOT',
          nodes: nodes3,
        },
      })
    })
  })
})
