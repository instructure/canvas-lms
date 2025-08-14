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

import {Flex} from '@instructure/ui-flex'
import {PreviewButton} from './PreviewButton'
import {RedoButton} from './RedoButton'
import {UndoButton} from './UndoButton'
import {useBlockContentEditorContext} from '../BlockContentEditorContext'
import {useEditHistory} from '../hooks/useEditHistory'

export const Toolbar = () => {
  const {
    editor: {mode, setMode},
  } = useBlockContentEditorContext()
  const {undo, redo, canUndo, canRedo} = useEditHistory()
  const isPreviewMode = mode === 'preview'

  return (
    <Flex direction="column">
      <UndoButton active={canUndo} onClick={undo} />
      <RedoButton active={canRedo} onClick={redo} />
      <PreviewButton
        active={isPreviewMode}
        onClick={() => setMode(isPreviewMode ? 'default' : 'preview')}
      />
    </Flex>
  )
}
