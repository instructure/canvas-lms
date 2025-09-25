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
import {SettingsTray, useSettingsTray} from './hooks/useSettingsTray'
import {useEditorMode} from './hooks/useEditorMode'
import {useEditingBlock} from './hooks/useEditingBlock'
import {useAccessibilityChecker} from './hooks/useAccessibilityChecker'

export type BlockContentEditorContextType = {
  addBlockModal: AddBlockModal
  settingsTray: SettingsTray
  editor: ReturnType<typeof useEditorMode>
  editingBlock: ReturnType<typeof useEditingBlock>
  accessibility: ReturnType<typeof useAccessibilityChecker>
  aiAltTextGenerationURL: string | null
}

export type BlockContentEditorContextProps = {
  data: SerializedNodes | null
  aiAltTextGenerationURL: string | null
}

const Context = createContext<BlockContentEditorContextType>(null as any)

export const useBlockContentEditorContext = () => useContext(Context)

export const BlockContentEditorContext = (
  props: PropsWithChildren<BlockContentEditorContextProps>,
) => {
  const addBlockModal = useAddBlockModal()
  const settingsTray = useSettingsTray()
  const editor = useEditorMode()
  const editingBlock = useEditingBlock()
  const accessibility = useAccessibilityChecker()
  const aiAltTextGenerationURL = props.aiAltTextGenerationURL

  return (
    <Context.Provider
      value={{
        addBlockModal,
        settingsTray,
        editor,
        editingBlock,
        accessibility,
        aiAltTextGenerationURL,
      }}
    >
      {props.children}
    </Context.Provider>
  )
}
