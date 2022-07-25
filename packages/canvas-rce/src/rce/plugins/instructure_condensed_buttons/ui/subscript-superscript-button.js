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
  const superAndSub = [
    {
      name: 'superscript',
      text: formatMessage('Superscript'),
      cmd: 'Superscript'
    },
    {
      name: 'subscript',
      text: formatMessage('Subscript'),
      cmd: 'Subscript'
    }
  ]
  const buttonLabel = formatMessage('Superscript and Subscript')

  editor.ui.registry.addSplitButton('inst_superscript', {
    tooltip: buttonLabel,
    icon: 'superscript',
    fetch: callback => {
      const items = superAndSub.map(button => {
        return {
          type: 'choiceitem',
          value: button.cmd,
          icon: button.name,
          text: button.text
        }
      })
      callback(items)
    },

    onAction: () => {
      const activeSetting = superAndSub.find(b => editor.formatter.match(b.name))
      const cmd = activeSetting ? activeSetting.cmd : 'Superscript'
      editor.execCommand(cmd)
    },

    onItemAction: (splitButtonApi, value) => editor.execCommand(value),

    select: value => {
      const button = superAndSub.find(b => b.cmd === value)
      return editor.formatter.match(button.name)
    },

    onSetup: api => {
      const $svgContainer = editor.$(
        `.tox-split-button[aria-label="${buttonLabel}"] .tox-icon`,
        document
      )
      const allIcons = editor.ui.registry.getAll().icons
      function nodeChangeHandler() {
        const activeButton = superAndSub.find(b => editor.formatter.match(b.name))
        const icon = activeButton ? activeButton.name : 'superscript'

        const svg = allIcons[icon]
        api.setActive(!!activeButton)
        $svgContainer.html(svg)
      }

      nodeChangeHandler()
      editor.on('NodeChange', nodeChangeHandler)
      return () => editor.off('NodeChange', nodeChangeHandler)
    }
  })
}
