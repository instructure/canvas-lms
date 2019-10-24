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

export default function(editor) {
  const alignToolbarButtons = [
    {
      name: 'alignleft',
      text: formatMessage('Align left'),
      cmd: 'JustifyLeft',
      icon: 'align-left'
    },
    {
      name: 'aligncenter',
      text: formatMessage('Align center'),
      cmd: 'JustifyCenter',
      icon: 'align-center'
    },
    {
      name: 'alignright',
      text: formatMessage('Align right'),
      cmd: 'JustifyRight',
      icon: 'align-right'
    }
  ]

  const alignButtonLabel = formatMessage('Align')

  editor.ui.registry.addSplitButton('align', {
    tooltip: alignButtonLabel,
    icon: 'align-left',
    presets: 'listpreview',
    columns: 3,

    fetch: callback => {
      const items = alignToolbarButtons.map(button => {
        return {
          type: 'choiceitem',
          value: button.cmd,
          icon: button.icon,
          text: button.text
        }
      })
      callback(items)
    },

    onAction: () => {
      const activeAlignment = alignToolbarButtons.find(b => editor.formatter.match(b.name))
      const cmd = activeAlignment ? activeAlignment.cmd : 'JustifyLeft'
      editor.execCommand(cmd)
    },

    onItemAction: (splitButtonApi, value) => editor.execCommand(value),

    select: value => {
      const button = alignToolbarButtons.find(b => b.cmd === value)
      return editor.formatter.match(button.name)
    },

    onSetup: api => {
      const $svgContainer = editor.$(
        editor.editorContainer.querySelector(`[aria-label="${alignButtonLabel}"] .tox-icon`)
      )
      const allIcons = editor.ui.registry.getAll().icons

      function nodeChangeHandler() {
        const activeAlignment = alignToolbarButtons.find(b => editor.formatter.match(b.name))
        const icon = activeAlignment ? activeAlignment.icon : 'align-left'
        const svg = allIcons[icon]
        api.setActive(!!activeAlignment)
        $svgContainer.html(svg)
      }

      editor.on('NodeChange', nodeChangeHandler)
      return () => editor.off('NodeChange', nodeChangeHandler)
    }
  })
}
