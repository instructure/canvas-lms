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
import {Editor} from 'tinymce'
import {toolbarIconHelperFor} from '../../../../util/tinymce-plugin-util'

export default function (editor: Editor) {
  const alignToolbarButtons = [
    {
      name: 'alignleft',
      text: formatMessage('Left Align'),
      cmd: 'JustifyLeft',
      icon: 'align-left',
    },
    {
      name: 'aligncenter',
      text: formatMessage('Center Align'),
      cmd: 'JustifyCenter',
      icon: 'align-center',
    },
    {
      name: 'alignright',
      text: formatMessage('Right Align'),
      cmd: 'JustifyRight',
      icon: 'align-right',
    },
  ]

  const alignButtonLabel = formatMessage('Align')

  editor.ui.registry.addMenuButton('align', {
    tooltip: alignButtonLabel,
    icon: 'align-left',
    fetch: callback =>
      callback(
        alignToolbarButtons.map(button => ({
          type: 'menuitem',
          value: button.cmd,
          icon: button.icon,
          text: button.text,
          onAction: () => editor.execCommand(button.cmd),
        }))
      ),

    onSetup: api => {
      const iconHelper = toolbarIconHelperFor(editor, alignButtonLabel)

      function nodeChangeHandler() {
        const activeAlignment = alignToolbarButtons.find(b => editor.formatter.match(b.name))
        const icon = activeAlignment ? activeAlignment.icon : 'align-left'

        api.setActive(!!activeAlignment)
        iconHelper.updateIcon(icon)
      }

      nodeChangeHandler()
      editor.on('NodeChange', nodeChangeHandler)
      return () => editor.off('NodeChange', nodeChangeHandler)
    },
  })
}
