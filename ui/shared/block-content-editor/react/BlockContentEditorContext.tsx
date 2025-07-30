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

import {createContext, PropsWithChildren, useContext} from 'react'
import {SerializedNodes} from '@craftjs/core'
import {AddBlockModal, useAddBlockModal} from './hooks/useAddBlockModal'
import {InitialAddBlockHandler, useInitialAddBlockHandler} from './hooks/useInitialAddBlockHandler'
import {SettingsTray, useSettingsTray} from './hooks/useSettingsTray'
import {useEditorMode} from './hooks/useEditorMode'

export type BlockContentEditorContextType = {
  addBlockModal: AddBlockModal
  initialAddBlockHandler: InitialAddBlockHandler
  settingsTray: SettingsTray
  editor: ReturnType<typeof useEditorMode>
}

export type BlockContentEditorContextProps = {
  data: SerializedNodes | null
}

const Context = createContext<BlockContentEditorContextType>(null as any)

export const useBlockContentEditorContext = () => useContext(Context)

export const BlockContentEditorContext = (
  props: PropsWithChildren<BlockContentEditorContextProps>,
) => {
  const addBlockModal = useAddBlockModal()
  const settingsTray = useSettingsTray()
  const initialAddBlockHandler = useInitialAddBlockHandler(props.data?.['ROOT']?.nodes.length ?? 0)
  const editor = useEditorMode()

  return (
    <Context.Provider
      value={{
        addBlockModal,
        initialAddBlockHandler,
        settingsTray,
        editor,
      }}
    >
      {props.children}
    </Context.Provider>
  )
}
