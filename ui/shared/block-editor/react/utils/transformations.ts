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

const LATEST_BLOCK_DATA_VERSION = '0.2' as const

type jsonString = string

type BlockEditorData_0_2 = {
  id?: string
  version: '0.2'
  blocks?: jsonString
}

type BlockType_0_1 = {
  data?: jsonString
}
type BlockEditorData_0_1 = {
  id?: string
  version: '0.1'
  blocks: BlockType_0_1[]
}

// BlockEditorData is the latest version of the data structure
type BlockEditorData = BlockEditorData_0_2

// any possible version of the data structure
type BlockEditorDataTypes = BlockEditorData | BlockEditorData_0_1

const transform = (data: BlockEditorDataTypes): BlockEditorData => {
  let transformedData = data

  if (data.version === '0.1') {
    transformedData = transform_0_1_to_0_2(data)
  }

  return transformedData as BlockEditorData
}

function transform_0_1_to_0_2(data: BlockEditorData_0_1): BlockEditorData_0_2 {
  const blocks = data.blocks[0].data

  return {
    id: data.id,
    version: '0.2',
    blocks,
  }
}

export {
  transform,
  transform_0_1_to_0_2,
  LATEST_BLOCK_DATA_VERSION,
  type BlockEditorData,
  type BlockEditorDataTypes,
  type BlockEditorData_0_1,
}
