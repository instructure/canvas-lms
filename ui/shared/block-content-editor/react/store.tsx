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

import {AccessibilityIssuesMap} from './accessibilityChecker/types'
import {EditorMode} from './hooks/useEditorMode'
import {configureStore, useGetStore, useSelector, useSetStore} from './utilities/fastContext'

export type BlockContentEditorStore = {
  addBlockModal: {
    isOpen: boolean
    insertAfterNodeId?: string
  }
  editor: {
    mode: EditorMode
  }
  accessibility: {
    a11yIssueCount: number
    a11yIssues: AccessibilityIssuesMap
  }
  settingsTray: {
    isOpen: boolean
    blockId?: string
  }
  editingBlock: {
    id: string | null
    viaEditButton: boolean
    saveCallbacks: Set<() => void>
  }
  focusTarget: {
    type: 'addButton' | 'insertButton' | 'copyButton' | null
    nodeId: string | null
  }
  aiAltTextGenerationURL: string | null
  toolbarReorder: boolean
}

export const createStore = (props: {
  aiAltTextGenerationURL: string | null
  toolbarReorder: boolean
}) =>
  configureStore<BlockContentEditorStore>({
    addBlockModal: {
      isOpen: false,
      insertAfterNodeId: undefined,
    },
    editor: {
      mode: 'default',
    },
    accessibility: {
      a11yIssueCount: 0,
      a11yIssues: new Map(),
    },
    settingsTray: {
      isOpen: false,
      blockId: undefined,
    },
    editingBlock: {
      id: null,
      viaEditButton: false,
      saveCallbacks: new Set(),
    },
    focusTarget: {
      type: null,
      nodeId: null,
    },
    aiAltTextGenerationURL: props.aiAltTextGenerationURL,
    toolbarReorder: props.toolbarReorder ?? false,
  })

export const useAppSelector = useSelector.withType<BlockContentEditorStore>()
export const useAppSetStore = useSetStore.withType<BlockContentEditorStore>()
export const useGetAppStore = useGetStore.withType<BlockContentEditorStore>()
