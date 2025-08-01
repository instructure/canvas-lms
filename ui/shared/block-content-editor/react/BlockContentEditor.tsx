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

import {SerializedNodes} from '@craftjs/core'
import {BlockContentEditorContext, useBlockContentEditorContext} from './BlockContentEditorContext'
import {BlockContentEditorLayout} from './layout/BlockContentEditorLayout'
import {Toolbar} from './Toolbar'
import {BlockContentEditorWrapper} from './BlockContentEditorWrapper'
import {BlockContentPreview} from './Preview/BlockContentPreview'
import {EditorMode} from './hooks/useEditorMode'
import {BlockContentEditorHandler} from './BlockContentEditorHandlerIntegration'

const getEditorForMode = (mode: EditorMode, props: BlockContentEditorProps) => {
  switch (mode) {
    case 'default':
      return <BlockContentEditorWrapper isEditMode={true} {...props} />
    case 'preview':
      return <BlockContentPreview />
    default:
      throw new Error(`Unsupported editor mode: ${mode}`)
  }
}

const BlockContentEditorContent = (props: BlockContentEditorProps) => {
  const {
    editor: {mode},
  } = useBlockContentEditorContext()
  const editor = getEditorForMode(mode, props)
  return <BlockContentEditorLayout toolbar={<Toolbar />} editor={editor} />
}

export type BlockContentEditorProps = {
  data: SerializedNodes | null
  onInit: ((handler: BlockContentEditorHandler) => void) | null
}

export const BlockContentEditor = (props: BlockContentEditorProps) => {
  return (
    <BlockContentEditorContext data={props.data}>
      <BlockContentEditorContent {...props} />
    </BlockContentEditorContext>
  )
}
