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

import {Editor, Frame, SerializedNodes} from '@craftjs/core'
import {BlockContentViewerLayout} from './layout/BlockContentViewerLayout'
import {components} from './block-content-editor-components'
import {BlockContentEditorErrorBoundary} from './BlockContentEditorErrorBoundary'

export type BlockContentViewerProps = {
  data: SerializedNodes | null
}

export const BlockContentViewer = (props: BlockContentViewerProps) => {
  const editor = <Frame data={props.data ?? undefined} />
  return (
    <BlockContentEditorErrorBoundary>
      <Editor enabled={false} resolver={components}>
        <BlockContentViewerLayout editor={editor} />
      </Editor>
    </BlockContentEditorErrorBoundary>
  )
}
