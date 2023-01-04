/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {Editor} from 'tinymce'

/**
 * Returns a helper for updating the icon of a toolbar button in a TinyMCE editor, necessary since there isn't a
 * built-in API for doing this, and RCE UX calls for toolbar buttons to be updated to match the user's selection
 * in the editor.
 *
 *
 * NOTE:
 * This function returns a helper that can later be used to actually update the icon. This is done so that
 * `toolbarIconHelperFor` can be called in the `onSetup` method of a button, such that any errors in finding the
 * icon in the toolbar will occur at RCE setup time, and not later, when user action occurs, thus increasing the
 * likelihood that those errors will be caught in tests, rather than being thrown at runtime as a result of user action
 */
export function toolbarIconHelperFor(editor: Editor, ariaLabel: string) {
  // There are a few different potential button selectors
  const containerSelector = ['.tox-tbtn', '.tox-split-button']
    .map(buttonSel => `${buttonSel}[aria-label="${CSS.escape(ariaLabel)}"] .tox-icon`)
    .join(',')

  const $svgContainer = editor.$(containerSelector, document)

  if ($svgContainer.length === 0) {
    console.error(
      `Failed to find TinyMCE toolbar button for ariaLabel "${ariaLabel}" using selector: ${containerSelector}`
    )
  }

  return {
    updateIcon(iconName: string) {
      const svg = editor.ui.registry.getAll().icons[iconName]

      if (!svg) {
        console.error(`Invalid icon name given for button labeled "${ariaLabel}": ${iconName}`)
      }

      $svgContainer.html(svg)
    },
  }
}
