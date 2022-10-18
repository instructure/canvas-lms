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

export default function (editor) {
  function defaultDirectionality() {
    return document.dir
  }

  const directionalityMenuItems = [
    {
      name: 'ltr',
      text: formatMessage('Left-to-Right'),
      cmd: 'mceDirectionLTR',
      icon: 'ltr',
    },
    {
      name: 'rtl',
      text: formatMessage('Right-to-Left'),
      cmd: 'mceDirectionRTL',
      icon: 'rtl',
    },
  ]

  if (defaultDirectionality() === 'rtl') directionalityMenuItems.reverse()

  // Register menu item
  editor.ui.registry.addNestedMenuItem('directionality', {
    text: formatMessage('Directionality'),
    getSubmenuItems: () => [directionalityMenuItems[0].name, directionalityMenuItems[1].name],
  })
  directionalityMenuItems.forEach(button => {
    editor.ui.registry.addMenuItem(button.name, {
      text: button.text,
      icon: button.icon,
      onAction: () => editor.execCommand(button.cmd),
    })
  })
}
