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

import {useEffect, useRef} from 'react'
import {useEditingBlock} from './useEditingBlock'
import {useAppSelector} from '../store'

export const useEditClickHandler = () => {
  const {setId} = useEditingBlock()
  const id = useAppSelector(state => state.editingBlock.id)
  const idRef = useRef(id)
  idRef.current = id

  useEffect(() => {
    const clickHandler = (ev: MouseEvent | TouchEvent) => {
      const target = ev.target as HTMLElement
      const itemExists = document.contains(target)
      const iframeClicked = document.activeElement?.nodeName === 'IFRAME'
      const dialogClicked = target.closest('[role="dialog"]')
      const ignoreClicked = target.closest('[data-ignore-edit-click]')
      if (!itemExists || iframeClicked || dialogClicked || ignoreClicked) {
        return
      }

      const actionButton = target.closest('[data-action-button]')
      const addButtonClicked = actionButton && actionButton.getAttribute('data-addbutton')
      const block = target.closest('[data-bce-node-id]')
      const blockClicked = block !== null
      if (!blockClicked || addButtonClicked) {
        setId(null)
        return
      }

      const nodeId = block.getAttribute('data-bce-node-id')!
      if (nodeId !== idRef.current) {
        if (actionButton) {
          setId(null)
        } else {
          setId(nodeId, false)
        }
      }
    }

    document.addEventListener('click', clickHandler)
    return () => {
      document.removeEventListener('click', clickHandler)
    }
  }, [])
}
