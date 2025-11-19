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
import {useScope as createI18nScope} from '@canvas/i18n'
import {PreviewButton} from './PreviewButton'
import {RedoButton} from './RedoButton'
import {UndoButton} from './UndoButton'
import {AccessibilityCheckerButton} from './AccessibilityCheckerButton'
import {ReorderBlocksButton} from './ReorderBlocksButton'
import {useEditHistory} from '../hooks/useEditHistory'
import {showScreenReaderAlert} from '../utilities/accessibility'
import {List} from '@instructure/ui-list'
import {useEditorMode} from '../hooks/useEditorMode'
import {useAppSelector} from '../store'
import {useGetBlocksCount} from '../hooks/useGetBlocksCount'

const I18n = createI18nScope('block_content_editor')

export const Toolbar = () => {
  const {a11yIssueCount, a11yIssues, toolbarReorder} = useAppSelector(state => ({
    ...state.accessibility,
    toolbarReorder: state.toolbarReorder,
  }))
  const {mode, setMode} = useEditorMode()
  const {undo, redo, canUndo, canRedo} = useEditHistory()
  const isPreviewMode = mode === 'preview'
  const {blocksCount} = useGetBlocksCount()

  const handleUndo = () => {
    undo()
    showScreenReaderAlert(I18n.t('Last change undone'))
  }

  const handleRedo = () => {
    redo()
    showScreenReaderAlert(I18n.t('Last change redone'))
  }

  const menuItems = [
    <PreviewButton
      active={isPreviewMode}
      onClick={() => setMode(isPreviewMode ? 'default' : 'preview')}
    />,
  ]
  if (!isPreviewMode) {
    menuItems.push(
      <UndoButton active={canUndo} onClick={handleUndo} />,
      <RedoButton active={canRedo} onClick={handleRedo} />,
    )

    if (toolbarReorder) {
      menuItems.push(<ReorderBlocksButton blockCount={blocksCount} />)
    }

    const allIssues = Array.from(a11yIssues.values()).flat()
    menuItems.push(<AccessibilityCheckerButton count={a11yIssueCount} issues={allIssues} />)
  }

  return (
    <View shadow="resting" display="block">
      <List isUnstyled margin="none">
        {menuItems.map((item, index) => (
          <List.Item key={index}>{item}</List.Item>
        ))}
      </List>
    </View>
  )
}
