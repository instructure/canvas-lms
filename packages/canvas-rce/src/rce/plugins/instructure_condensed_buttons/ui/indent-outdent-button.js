/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import formatMessage from '../../../../format-message'

export default function register(editor) {
  const baseIndentButton = {
    tooltip: formatMessage('Increase indent'),
    icon: 'indent',
    onAction: () => editor.execCommand('indent')
  }
  editor.ui.registry.addButton('inst_indent', baseIndentButton)

  editor.ui.registry.addSplitButton('inst_outdent', {
    ...baseIndentButton,
    presets: 'listpreview',
    columns: 3,
    fetch: callback => {
      callback([
        {
          type: 'choiceitem',
          icon: 'outdent',
          text: formatMessage('Decrease indent')
        }
      ])
    },
    onItemAction: () => editor.execCommand('outdent'),
    onSetup: () => {
      function showHideButtons(canOutdent) {
        editor
          .$(`.tox-tbtn[aria-label="${baseIndentButton.tooltip}"]`, document)
          [canOutdent ? 'hide' : 'show']()
        editor
          .$(`.tox-split-button[aria-label="${baseIndentButton.tooltip}"]`, document)
          [canOutdent ? 'show' : 'hide']()
      }
      function onNodeChange() {
        const canOutdent = editor.queryCommandState('outdent')
        showHideButtons(canOutdent)
      }
      setTimeout(onNodeChange) // hide one of the buttons on first render

      editor.on('NodeChange', onNodeChange)
      return () => editor.off('NodeChange', onNodeChange)
    }
  })
}
