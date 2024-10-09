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

import {
  transform,
  transform_0_1_to_0_2,
  LATEST_BLOCK_DATA_VERSION,
  type BlockEditorData,
  type BlockEditorDataTypes,
  type BlockEditorData_0_1,
} from '../transformations'

describe('transformations', () => {
  it('returns the same data if the version is the latest', () => {
    const data: BlockEditorData = {
      version: LATEST_BLOCK_DATA_VERSION,
      blocks: 'blocks',
    }
    expect(transform(data)).toEqual(data)
  })

  it('transforms version 0.1 to the latest version', () => {
    const data: BlockEditorDataTypes = {
      version: '0.1',
      blocks: [{data: 'blocks'}],
    }
    expect(transform(data)).toEqual({
      version: LATEST_BLOCK_DATA_VERSION,
      blocks: 'blocks',
    })
  })

  describe('transform 0.1 to 0.2', () => {
    it('transforms data', () => {
      const data: BlockEditorData_0_1 = {
        version: '0.1',
        blocks: [{data: 'blocks'}],
      }
      expect(transform_0_1_to_0_2(data)).toEqual({
        version: '0.2',
        blocks: 'blocks',
      })
    })
  })
})
