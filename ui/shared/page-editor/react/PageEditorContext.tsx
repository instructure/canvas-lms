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

import {createContext, PropsWithChildren, useContext, useState} from 'react'
import {Prettify} from './utilities/Prettify'

type AddBlockModal = {
  isOpen: boolean
  insertAfterNodeId?: string
  open: (insertAfterNodeId?: string) => void
  close: () => void
}

type PageEditorContextType = {
  addBlockModal: AddBlockModal
}

const Context = createContext<PageEditorContextType>(null as any)

export const usePageEditorContext = () => useContext(Context)

export const PageEditorContext = (props: PropsWithChildren) => {
  const [addBlockModal, setAddBlockModal] = useState<
    Prettify<Pick<AddBlockModal, 'isOpen' | 'insertAfterNodeId'>>
  >({
    isOpen: false,
    insertAfterNodeId: undefined,
  })
  const openAddBlockModal = (insertAfterNodeId?: string) => {
    setAddBlockModal({
      isOpen: true,
      insertAfterNodeId,
    })
  }
  const closeAddBlockModal = () => {
    setAddBlockModal({
      isOpen: false,
      insertAfterNodeId: undefined,
    })
  }

  return (
    <Context.Provider
      value={{
        addBlockModal: {
          ...addBlockModal,
          open: openAddBlockModal,
          close: closeAddBlockModal,
        },
      }}
    >
      {props.children}
    </Context.Provider>
  )
}
