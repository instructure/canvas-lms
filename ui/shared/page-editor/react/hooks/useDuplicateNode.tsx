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

import {useCallback} from 'react'
import {useEditor, useNode} from '@craftjs/core'
import {useAddNode} from './useAddNode'

export const useDuplicateNode = () => {
  const {id} = useNode()
  const {query} = useEditor()
  const addNode = useAddNode()

  const duplicateNode = useCallback(() => {
    // This assumes one level of blocks!
    const {data} = query.node(id).get()
    const Type = data.type
    const props = data.props || {}

    addNode(<Type {...props} />, id)
  }, [addNode, query, id])

  return duplicateNode
}
