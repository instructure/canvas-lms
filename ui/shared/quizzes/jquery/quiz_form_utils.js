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

export function renderError(inputContainer, message) {
    const inputMessageContainer = inputContainer.find('.input-message__container')

    if (!inputMessageContainer.length) {
      console.warn('renderError was called on a non-message container', inputContainer)
      return
    }

    const inputField = inputContainer.find('input').last()
    const inputMessageText = inputMessageContainer.find('.input-message__text')

    inputContainer.addClass('invalid')
    inputField.attr('aria-invalid', 'true')
    inputMessageContainer.addClass('error').removeClass('hidden')
    inputMessageText
      .attr({
        'aria-live': 'polite',
        'aria-atomic': 'true'
      })
      .text(message)
    inputMessageText.addClass('error_text')

    inputContainer.find('.asterisk').addClass('error')
}

export function restoreOriginalMessage(inputContainer) {
    const inputMessageContainer = inputContainer.find('.input-message__container')
    const inputField = inputContainer.find('input').last()
    const textToRestore = inputMessageContainer.data('original-text') || ''
    const inputMessageText = inputMessageContainer.find('.input-message__text')

    inputContainer.removeClass('invalid')
    inputField.removeAttr('aria-invalid')
    inputMessageContainer.removeClass('error')

    inputMessageText.removeAttr('aria-live').removeAttr('aria-atomic').text(textToRestore)
      .removeClass('error_text')

    inputContainer.find('.asterisk').removeClass('error')

    if (textToRestore === '') {
      inputMessageContainer.addClass('hidden')
    }
}
