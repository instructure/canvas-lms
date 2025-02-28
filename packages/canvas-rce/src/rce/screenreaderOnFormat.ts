/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import type {Editor, EditorEvent, Events} from 'tinymce'
import formatMessage from '../format-message'

const screenreaderMessageHolderId = 'rce_message_screenreader_holder'

const getAlertContainer = () => {
  let alertContainer = document.getElementById(screenreaderMessageHolderId)
  if (!alertContainer) {
    alertContainer = document.createElement('div')
    alertContainer.id = screenreaderMessageHolderId
    alertContainer.setAttribute('role', 'status')
    alertContainer.setAttribute('aria-live', 'assertive')
    alertContainer.setAttribute('aria-relevant', 'additions')
    alertContainer.setAttribute('aria-atomic', 'true')
    // copied from Canvas' .screenreader-only
    alertContainer.setAttribute(
      'style',
      'border: 0; clip: rect(0 0 0 0); height: 1px; margin: -1px; overflow: hidden; padding: 0; position: absolute; width: 1px; transform: translatez(0);',
    )
    document.body.appendChild(alertContainer)
  }
  return alertContainer
}

const announce = (message: string) => {
  const alertContainer = getAlertContainer()
  const messageElement = document.createElement('span')
  messageElement.textContent = message
  alertContainer.replaceChildren(messageElement)
}

const handleFormatApply = (event: EditorEvent<Events.FormatEvent>) => {
  switch (event.format) {
    case 'bold':
      announce(formatMessage('Bold applied'))
      break
    case 'italic':
      announce(formatMessage('Italic applied'))
      break
    case 'underline':
      announce(formatMessage('Underline applied'))
      break
    case 'h1':
    case 'h2':
    case 'h3':
    case 'h4':
    case 'h5':
    case 'h6':
      announce(formatMessage('Heading {h} applied', {h: event.format}))
      break
    case 'p':
      announce(formatMessage('Paragraph applied'))
      break
    case 'div':
      announce(formatMessage('Div applied'))
      break
    case 'address':
      announce(formatMessage('Address applied'))
      break
  }
}

const handleRemoveFormat = (event: EditorEvent<Events.FormatEvent>) => {
  switch (event.format) {
    case 'bold':
      announce(formatMessage('Bold removed'))
      break
    case 'italic':
      announce(formatMessage('Italic removed'))
      break
    case 'underline':
      announce(formatMessage('Underline removed'))
      break
    case 'h1':
    case 'h2':
    case 'h3':
    case 'h4':
    case 'h5':
    case 'h6':
      announce(formatMessage('Heading {h} removed', {h: event.format}))
      break
    case 'p':
      announce(formatMessage('Paragraph removed'))
      break
    case 'div':
      announce(formatMessage('Div removed'))
      break
    case 'address':
      announce(formatMessage('Address removed'))
      break
  }
}

export const initScreenreaderOnFormat = (editor: Editor) => {
  editor.on('FormatApply', handleFormatApply)
  editor.on('FormatRemove', handleRemoveFormat)
}
