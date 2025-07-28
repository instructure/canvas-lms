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

// There are two cases for transformation, the data stored in the block_editors table
// and the data stored in the block_templates table. In either case we may have to transform
// the data structure at-large (rarely), and we may have to transformt the blocks data.
// In Pages, the data is in ENV.WIKI_PAGE.block_editor_attributes and looks like
//  {id: "1", version: "0.x", blocks: '{"ROOT":{"type":{"resolvedName":"PageBlock"},...'}}'
// In templates the data looks like
//  {version: "0.x", node_tree: {rootNodeId: "ROOT", nodes: {ROOT: {type: {resolvedName: 'PageBlock'},...}}}}
//

import type {BlockTemplate, NodeTreeNodes} from '../types'

const LATEST_BLOCK_DATA_VERSION = '0.3' as const

const DEFAULT_CONTENT = {
  ROOT: {
    type: {
      resolvedName: 'PageBlock',
    },
    isCanvas: true,
    props: {},
    displayName: 'Page',
    custom: {
      isDefaultPage: true,
    },
    hidden: false,
    nodes: [],
    linkedNodes: {},
    parent: null,
  },
}

type jsonString = string

type BlockEditorData_0_3 = {
  id?: string
  version: '0.3'
  blocks?: NodeTreeNodes
}

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
type TransformableData = {
  id?: string
  version: string
  blocks?: jsonString | NodeTreeNodes | BlockType_0_1[]
}

// the latest version of the data structure
type BlockEditorData = BlockEditorData_0_3

// any possible version of the data structure
type BlockEditorDataTypes = BlockEditorData_0_1 | BlockEditorData_0_2 | BlockEditorData_0_3

const transformTemplate = (template: BlockTemplate): BlockTemplate => {
  if (!template.node_tree) {
    template.editor_version = LATEST_BLOCK_DATA_VERSION
    return template
  }
  if (template.editor_version === LATEST_BLOCK_DATA_VERSION) {
    return template
  }

  const data = {
    id: template.id,
    version: template.editor_version,
    blocks: template.node_tree.nodes,
  }
  const transformeData = transform(data)

  return {
    ...template,
    editor_version: transformeData.version,
    node_tree: {
      rootNodeId: template.node_tree.rootNodeId,
      nodes: transformeData.blocks as NodeTreeNodes,
    },
  }
}

const transform = (data: TransformableData): BlockEditorData => {
  let transformedData = data

  if (transformedData.version === '0.1') {
    transformedData = transform_0_1_to_0_2(transformedData as BlockEditorData_0_1)
  }
  if (transformedData.version === '0.2') {
    transformedData = transform_0_2_to_0_3(transformedData as BlockEditorData_0_2)
  }

  return transformedData as BlockEditorData
}

function transform_0_1_to_0_2(data: BlockEditorData_0_1): BlockEditorData_0_2 {
  return {
    id: data.id,
    version: '0.2',
    blocks: data.blocks[0].data,
  }
}

function transform_0_2_to_0_3(data: BlockEditorData_0_2): BlockEditorData_0_3 {
  if (!data.blocks) {
    return {
      id: data.id,
      version: '0.3',
      blocks: DEFAULT_CONTENT,
    }
  }

  const blocks = typeof data.blocks === 'string' ? JSON.parse(data.blocks) : data.blocks

  Object.keys(blocks).forEach(key => {
    const block = blocks[key]
    if (block.type.resolvedName === 'RCEBlock') {
      block.type.resolvedName = 'RCETextBlock'
    }
  })

  return {
    id: data.id,
    version: '0.3',
    blocks,
  }
}

export {
  transformTemplate,
  transform,
  transform_0_1_to_0_2,
  transform_0_2_to_0_3,
  LATEST_BLOCK_DATA_VERSION,
  type BlockEditorData,
  type BlockEditorDataTypes,
  type BlockEditorData_0_1,
  type BlockEditorData_0_2,
  type BlockEditorData_0_3,
}
