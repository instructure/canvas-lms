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

import {useCallback, useState} from 'react'
import {Prettify} from '../utilities/Prettify'

export type AddBlockModal = {
  isOpen: boolean
  insertAfterNodeId?: string
  open: (insertAfterNodeId?: string) => void
  close: () => void
}

export const useAddBlockModal = () => {
  const [modalState, setModalState] = useState<
    Prettify<Pick<AddBlockModal, 'isOpen' | 'insertAfterNodeId'>>
  >({
    isOpen: false,
    insertAfterNodeId: undefined,
  })

  const open = useCallback((insertAfterNodeId?: string) => {
    setModalState({
      isOpen: true,
      insertAfterNodeId,
    })
  }, [])

  const close = useCallback(() => {
    setModalState({
      isOpen: false,
      insertAfterNodeId: undefined,
    })
  }, [])

  return {
    ...modalState,
    open,
    close,
  }
}
