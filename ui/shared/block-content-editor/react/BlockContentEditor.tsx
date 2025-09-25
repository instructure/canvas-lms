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

import {BlockContentEditorContext, useBlockContentEditorContext} from './BlockContentEditorContext'
import {BlockContentEditorLayout} from './layout/BlockContentEditorLayout'
import {Toolbar} from './Toolbar'
import {BlockContentPreview} from './Preview/BlockContentPreview'
import {EditorMode} from './hooks/useEditorMode'
import {BlockContentEditorHandler} from './BlockContentEditorHandlerIntegration'
import {BlockContentViewerProps} from './BlockContentViewer'
import {Editor} from '@craftjs/core'
import {components} from './block-content-editor-components'
import {BlockContentEditorContent} from './BlockContentEditorContent'
import {BlockContentEditorErrorBoundary} from './BlockContentEditorErrorBoundary'
import {QueryClientProvider} from '@tanstack/react-query'
import {queryClient} from '@canvas/query'

const getEditorForMode = (mode: EditorMode, props: BlockContentEditorProps) => {
  switch (mode) {
    case 'default':
      return <BlockContentEditorContent {...props} />
    case 'preview':
      return <BlockContentPreview />
    default:
      throw new Error(`Unsupported editor mode: ${mode}`)
  }
}

const BlockContentEditorWrapper = (props: BlockContentEditorProps) => {
  const {
    editor: {mode},
  } = useBlockContentEditorContext()
  const editor = getEditorForMode(mode, props)
  return (
    <Editor enabled={mode === 'default'} resolver={components}>
      <BlockContentEditorLayout toolbar={<Toolbar />} editor={editor} mode={mode} />
    </Editor>
  )
}

export type BlockContentEditorProps = BlockContentViewerProps & {
  onInit: ((handler: BlockContentEditorHandler) => void) | null
  aiAltTextGenerationURL: string | null
}

export const BlockContentEditor = (props: BlockContentEditorProps) => {
  return (
    <QueryClientProvider client={queryClient}>
      <BlockContentEditorErrorBoundary>
        <BlockContentEditorContext
          data={props.data}
          aiAltTextGenerationURL={props.aiAltTextGenerationURL}
        >
          <BlockContentEditorWrapper {...props} />
        </BlockContentEditorContext>
      </BlockContentEditorErrorBoundary>
    </QueryClientProvider>
  )
}
