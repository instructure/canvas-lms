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

import {type BlockTemplate} from '../../../../types'

// @ts-expect-error
export const testTemplates = [
  {
    name: 'Blank',
    description: 'A blank template',
    template_type: 'section',
    id: '1',
    global_id: '1',
    node_tree: {
      rootNodeId: 'aaa',
      nodes: {
        aaa: {
          data: {
            displayName: 'BlankSection',
            linkedNodes: {},
            nodes: [],
          },
        },
      },
    },
    workflow_state: 'active',
    thumbnail: 'thumbnail1',
    template_category: 'global',
  },
  {
    name: 'Another Section',
    description: 'Another section template',
    template_type: 'section',
    id: '2',
    global_id: '2',
    node_tree: {
      rootNodeId: 'bbb',
      nodes: {
        bbb: {
          data: {
            displayName: 'ASection',
            linkedNodes: {},
            nodes: [],
          },
        },
      },
    },
    workflow_state: 'active',
    thumbnail: 'thumbnail2',
  },
  {
    name: 'A block template',
    description: 'A block template',
    id: '3',
    global_id: '3',
    template_type: 'block',
    node_tree: {
      rootNodeId: 'ccc',
      nodes: {
        ccc: {
          data: {
            linkedNodes: {},
            nodes: [],
          },
        },
      },
    },
    workflow_state: 'active',
    thumbnail: 'thumbnail3',
  },
  {
    name: 'block template 2',
    description: 'Another block template',
    id: '4',
    global_id: '4',
    template_type: 'block',
    node_tree: {
      rootNodeId: 'ddd',
      nodes: {
        ddd: {
          data: {
            linkedNodes: {},
            nodes: [],
          },
        },
      },
    },
    workflow_state: 'unpublished',
    thumbnail: 'thumbnail4',
  },
] as BlockTemplate[]
