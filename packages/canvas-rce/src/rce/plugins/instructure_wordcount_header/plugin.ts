/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import tinymce from 'tinymce'
import formatMessage from '../../../format-message'
import {debounce} from '@instructure/debounce'

const clickCallbackPromise = import('../instructure_wordcount/clickCallback')

const TOOLTIP_MESSAGE = formatMessage('View word and character counts')
const UPDATE_DEBOUNCE_MS = 100

function formatWordCount(count: number): string {
  return formatMessage(
    `{count, plural,
       =0 {0 words}
      one {1 word}
    other {# words}
  }`,
    {count},
  )
}

tinymce.PluginManager.add('instructure_wordcount_header', function (ed: any) {
  function updateWordCountDisplay() {
    const count = ed.plugins.wordcount.body.getWordCount()

    const button = ed.getContainer()?.querySelector(`[title*="${TOOLTIP_MESSAGE}"]`)
    if (!button) {
      return
    }

    const textSpan = button.querySelector('.tox-tbtn__select-label')
    if (textSpan) {
      textSpan.textContent = formatWordCount(count)
    }

    const tooltip = `${TOOLTIP_MESSAGE} - ${formatWordCount(count)}`
    button.setAttribute('title', tooltip)
    button.setAttribute('aria-label', tooltip)
  }

  ed.addCommand('instructureWordCountHeader', () => {
    clickCallbackPromise.then(module => module.default(ed, document, {skipEditorFocus: false}))
  })

  ed.ui.registry.addButton('instructure_wordcount_header', {
    text: formatWordCount(0),
    tooltip: TOOLTIP_MESSAGE,
    onAction: () => ed.execCommand('instructureWordCountHeader'),
  })

  ed.on('PostRender', () => {
    updateWordCountDisplay()
  })

  const debouncedUpdate = debounce(updateWordCountDisplay, UPDATE_DEBOUNCE_MS, {trailing: true})

  ed.on('NodeChange', debouncedUpdate)
  ed.on('KeyUp', debouncedUpdate)
  ed.on('SetContent', debouncedUpdate)
  ed.on('Change', debouncedUpdate)
  ed.on('Undo', debouncedUpdate)
  ed.on('Redo', debouncedUpdate)
  ed.on('Paste', debouncedUpdate)

  ed.on('init', () => {
    updateWordCountDisplay()
  })
})
