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
  const superAndSub = {
    superscript: formatMessage('Superscript'),
    subscript: formatMessage('Subscript')
  }

  Object.keys(superAndSub).forEach(key => {
    const oppositeKey = key === 'superscript' ? 'subscript' : 'superscript'
    editor.ui.registry.addSplitButton(key, {
      presets: 'listpreview',
      columns: 3,
      tooltip: superAndSub[key],
      icon: key,
      fetch: cb => {
        cb([
          {
            type: 'choiceitem',
            icon: oppositeKey,
            text: superAndSub[oppositeKey]
          }
        ])
      },

      onAction: () => editor.execCommand('mceToggleFormat', false, key),
      onItemAction: () => editor.execCommand('mceToggleFormat', false, oppositeKey),
      onSetup(api) {
        const $button = editor.$(
          editor.editorContainer.querySelector(
            `.tox-split-button[aria-label="${superAndSub[key]}"]`
          )
        )
        function onNodeChange() {
          const iMatch = editor.formatter.match(key)
          const showButton =
            iMatch || (key === 'superscript' && !editor.formatter.match(oppositeKey))
          $button[showButton ? 'show' : 'hide']()
          api.setActive(iMatch)
        }
        onNodeChange()
        editor.on('NodeChange', onNodeChange)
        return () => editor.off('NodeChange', onNodeChange)
      }
    })
  })
}
