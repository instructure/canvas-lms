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

import {QueryMethods, SerializedNodes, useEditor} from '@craftjs/core'
import {QueryCallbacksFor} from '@craftjs/utils'
import {useEffect, useRef} from 'react'
import {useEditHistory} from './hooks/useEditHistory'

export interface BlockContentEditorHandler {
  getContent: () => {
    blocks: SerializedNodes
  }
  isEdited: () => boolean
}

export const BlockContentEditorHandlerIntegration = (props: {
  onInit: ((handler: BlockContentEditorHandler) => void) | null
}) => {
  const {query} = useEditor()
  const {isEdited} = useEditHistory()

  const queryRef = useRef<QueryCallbacksFor<typeof QueryMethods> | null>(null)
  const isEditedRef = useRef<boolean | null>(null)
  queryRef.current = query
  isEditedRef.current = isEdited

  useEffect(() => {
    const handler: BlockContentEditorHandler = {
      getContent: () => ({
        blocks: queryRef.current ? JSON.parse(queryRef.current.serialize()) : null,
      }),
      isEdited: () => !!isEditedRef.current,
    }
    props.onInit?.(handler)
  }, [props.onInit])

  return null
}
