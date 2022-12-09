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

export default function register(editor: Editor) {
  const indentButtons = [
    {
      name: 'indent',
      text: formatMessage('Increase Indent'),
      cmd: 'indent',
    },
    {
      name: 'outdent',
      text: formatMessage('Decrease Indent'),
      cmd: 'outdent',
    },
  ]

  const buttonLabel = formatMessage('Increase Indent')

  editor.ui.registry.addMenuButton('inst_indent', {
    tooltip: buttonLabel,
    icon: 'indent',

    fetch: callback =>
      callback(
        indentButtons.map(button => ({
          type: 'menuitem',
          value: button.cmd,
          icon: button.name,
          text: button.text,
          onAction: () => editor.execCommand(button.cmd),
        }))
      ),
  })
}
