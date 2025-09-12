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

import {View} from '@instructure/ui-view'
import {PreviewButton} from './PreviewButton'
import {RedoButton} from './RedoButton'
import {UndoButton} from './UndoButton'
import {AccessibilityCheckerButton} from './AccessibilityCheckerButton'
import {useBlockContentEditorContext} from '../BlockContentEditorContext'
import {useEditHistory} from '../hooks/useEditHistory'
import {List} from '@instructure/ui-list'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block_content_editor')

export const Toolbar = () => {
  const {
    editor: {mode, setMode},
    accessibility: {a11yIssueCount, a11yIssues},
  } = useBlockContentEditorContext()
  const {undo, redo, canUndo, canRedo} = useEditHistory()
  const isPreviewMode = mode === 'preview'

  const allIssues = Array.from(a11yIssues.values()).flat()

  return (
    <View shadow="resting" display="block">
      <List role="toolbar" aria-label={I18n.t('Editor toolbar')} isUnstyled margin="none">
        <List.Item>
          <PreviewButton
            active={isPreviewMode}
            onClick={() => setMode(isPreviewMode ? 'default' : 'preview')}
          />
        </List.Item>
        {!isPreviewMode && (
          <>
            <List.Item>
              <UndoButton active={canUndo} onClick={undo} />
            </List.Item>
            <List.Item>
              <RedoButton active={canRedo} onClick={redo} />
            </List.Item>
            <List.Item>
              <AccessibilityCheckerButton count={a11yIssueCount} issues={allIssues} />
            </List.Item>
          </>
        )}
      </List>
    </View>
  )
}
