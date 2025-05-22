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

import {type SerializedNode} from '@craftjs/core'

// A custom type constraint that enforces at least one key is present
export type AtLeastOne<T, U = {[K in keyof T]: Pick<T, K>}> = Partial<T> & U[keyof U]

export type CanEditTemplates = {
  can_edit: boolean
  can_edit_global: boolean
}

export type TemplateType = 'page' | 'section' | 'block'
export type WorkflowState = 'active' | 'deleted' | 'unpublished'

export enum TemplateEditor {
  UNKNOWN = -1,
  NONE = 0,
  LOCAL = 1,
  GLOBAL = 2,
}

export type NodeTreeNodes = Record<string, SerializedNode>

export type TemplateNodeTree = {
  rootNodeId: string
  nodes: NodeTreeNodes
}

export type TemplateCategory = 'global' | 'local'

export type BlockTemplate = {
  id: string
  global_id?: string
  context_type: string
  context_id: string
  name: string
  description?: string | null
  tags?: string[]
  node_tree?: TemplateNodeTree
  editor_version: string
  template_type: TemplateType
  template_category?: TemplateCategory
  thumbnail?: string
  workflow_state: WorkflowState
}

export type BlockTemplateGridItemProps = {
  createAction: () => void
  template?: BlockTemplate
}

export type ChooseEditorModalProps = {
  editorFeature: EditorFeatures
  createPageAction: any
  onClose: any
}

export const SaveTemplateEvent = 'block-editor-save-block-template' as const
export const DeleteTemplateEvent = 'block-editor-delete-block-template' as const
export const PublishTemplateEvent = 'block-editor-publish-block-template' as const

export const dispatchTemplateEvent = (event: CustomEvent) => {
  const blockEditorEditor = document.querySelector('.block-editor-editor')
  blockEditorEditor?.dispatchEvent(event)
}

export type EditorTypes = 'rce' | 'block_editor' | ''
export type EditorFeatures = 'canvas_content_builder' | 'block_editor' | null
export type EditorPrefEnv = {
  text_editor_preference: EditorTypes
  EDITOR_FEATURE: EditorFeatures
}
