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

export default function register(editor: Editor) {
  const styleInfos = [
    {
      icon: 'superscript',
      text: formatMessage('Superscript'),
      cmd: 'Superscript',
    },
    {
      icon: 'subscript',
      text: formatMessage('Subscript'),
      cmd: 'Subscript',
    },
  ]

  const buttonLabel = formatMessage('Superscript and Subscript')
  const defaultIcon = styleInfos[0].icon

  editor.ui.registry.addMenuButton('inst_superscript', {
    tooltip: buttonLabel,
    icon: defaultIcon,
    fetch: callback =>
      callback(
        styleInfos.map(button => ({
          type: 'menuitem',
          value: button.cmd,
          icon: button.icon,
          text: button.text,
          onAction: () => editor.execCommand(button.cmd),
        }))
      ),

    onSetup: api => {
      const iconHelper = toolbarIconHelperFor(editor, buttonLabel)

      function nodeChangeHandler() {
        const activeStyleInfo = styleInfos.find(b => editor.formatter.match(b.icon))

        api.setActive(!!activeStyleInfo)
        iconHelper.updateIcon(activeStyleInfo?.icon || defaultIcon)
      }

      nodeChangeHandler()
      editor.on('NodeChange', nodeChangeHandler)
      return () => editor.off('NodeChange', nodeChangeHandler)
    },
  })
}
