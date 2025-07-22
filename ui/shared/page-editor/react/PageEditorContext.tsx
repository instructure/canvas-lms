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
import {SerializedNodes} from '@craftjs/core'
import {AddBlockModal, useAddBlockModal} from './hooks/useAddBlockModal'
import {InitialAddBlockHandler, useInitialAddBlockHandler} from './hooks/useInitialAddBlockHandler'

export type PageEditorContextType = {
  addBlockModal: AddBlockModal
  initialAddBlockHandler: InitialAddBlockHandler
}

export type PageEditorContextProps = {
  data: SerializedNodes | null
}

const Context = createContext<PageEditorContextType>(null as any)

export const usePageEditorContext = () => useContext(Context)

export const PageEditorContext = (props: PropsWithChildren<PageEditorContextProps>) => {
  const addBlockModal = useAddBlockModal()
  const initialAddBlockHandler = useInitialAddBlockHandler(props.data?.['ROOT']?.nodes.length ?? 0)

  return (
    <Context.Provider
      value={{
        addBlockModal,
        initialAddBlockHandler,
      }}
    >
      {props.children}
    </Context.Provider>
  )
}
