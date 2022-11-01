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

/** ********************************************************
 * This file holds a mostly functional paste menu command
 * We decided not to use it since menu-past and kb-paste
 * would be subtly different. Keeping the file here
 * because figuring this stuff out wasn't trivial and
 * I didn't want to lose it.
 ********************************************************* */

import formatMessage from '../../../format-message'
import {showFlashAlert} from '../../../common/FlashAlert'

export function initPasteMenuCommand(ed, handlePasteOrDrop) {
  // the paste menu command is problematic in that it requires
  // we get the copied data using the clipboard api, which is
  // more limited than what the browser can do natively via
  // meta+v.
  // For example, if the user copies a file from the Finder,
  // pasting via the menu command just gets you the filename.
  ed.addCommand('instructurePaste', () => {
    handlePasteMenuCommand()
  })

  ed.ui.registry.addMenuItem('instructure_paste', {
    text: formatMessage('Paste'),
    icon: 'paste',
    onAction: () => ed.execCommand('instructurePaste'),
    onSetup(_api) {
      // If I add the shortcut, then it overwrites the browsers
      // built-in keyboard shortcut for paste. we don't want that
      ed.addShortcut('meta+v', null, () => {
        ed.execCommand('instructurePaste')
      })
    },
  })
  async function handlePasteMenuCommand() {
    try {
      const cbitems = await window.navigator.clipboard.read()
      const cbitem = cbitems[0]
      const imageType = cbitem.types.find(t => /^image\//.test(t))
      if (imageType) {
        const blob = await cbitem.getType(imageType)
        const file = new File([blob], imageType.replace('/', '.'), {type: imageType})
        handlePasteOrDrop({
          clipboardData: {files: [file], types: ['Files']},
          preventDefault: () => {},
        })
      } else if (cbitem.types.includes('text/html')) {
        const blob = await cbitem.getType('text/html')
        const text = await blob.text()
        handlePasteOrDrop({
          clipboardData: {
            files: [],
            types: ['text/html'],
            getData: () => text,
          },
          preventDefault: () => {},
        })
      } else if (cbitem.types.includes('text/plain')) {
        const blob = await cbitem.getType('text/plain')
        const text = await blob.text()
        handlePasteOrDrop({
          clipboardData: {
            files: [],
            types: ['text/plain'],
            getData: () => text,
          },
          preventDefault: () => {},
        })
      } else {
        const textType = cbitem.types.find(t => /^text\//.test(t))
        if (textType) {
          const blob = await cbitem.getType(textType)
          const text = await blob.text()
          handlePasteOrDrop({
            clipboardData: {
              files: [],
              types: [textType],
              getData: () => text,
            },
            preventDefault: () => {},
          })
        }
      }
    } catch (ex) {
      showFlashAlert({message: 'whoops:', err: ex, type: 'error'})
    }
  }
}
