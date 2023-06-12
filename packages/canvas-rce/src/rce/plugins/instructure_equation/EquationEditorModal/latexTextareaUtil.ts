/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {
  performTextEditActionOnTextarea,
  TextEditAction,
} from '../../../../util/textarea-editing-util'

/**
 * Inserts text into a textarea for editing LaTeX, handling selection and focus management.
 *
 * Ultimately, this should be refactored out into a React component.
 *
 * @param textarea
 * @param insertionText
 */
export function insertTextIntoLatexTextarea(textarea: HTMLTextAreaElement, insertionText: string) {
  const currentText = textarea?.value ?? ''
  const selStart = textarea?.selectionStart ?? currentText.length
  const selEnd = textarea?.selectionEnd ?? selStart

  textarea.focus()

  planInsertTextIntoLatexTextarea({
    insertionText,
    currentText,
    selStart,
    selEnd,
  }).forEach(action => performTextEditActionOnTextarea(textarea, action))
}

export function planInsertTextIntoLatexTextarea(args: {
  currentText: string
  selStart: number
  selEnd: number
  insertionText: string
}): TextEditAction[] {
  const {insertionText} = args

  const {currentText, selStart, selEnd} = args

  const selectedText = currentText.substring(selStart, selEnd)

  // Look for parameters ([] or {}) in the command text, because we'll want to wrap the current selection in the
  // command in that case
  const singleParamParts = insertionText.match(
    // Match both [] and {}
    /^(.*?\{)\s*(}.*)$|^(.*?\[)\s*(].*)$/
  )
  const doubleParamParts = insertionText.match(
    // Match two sets of [] and/or {}
    /^(?:(.*?\{)\s*(}.*?)|(.*?\[)\s*(].*?))(?:(.*?\{)\s*(}.*?)|(.*?\[)\s*(].*))$/
    //   1         2      3         4         5         6      7         8
  )

  if (doubleParamParts) {
    const m = doubleParamParts

    const before = m[1] ?? m[3] ?? ''
    const middle = (m[2] ?? m[4] ?? '') + (m[5] ?? m[7] ?? '')
    const after = m[6] ?? m[8] ?? ''

    if (selectedText.length) {
      // When there is a selection with a double-parameter command, the selection should fill the first parameter
      // and the cursor should be be placed in the second parameter
      return [
        {action: 'insert', text: before + selectedText + middle},
        {action: 'wrapSelection', before: '', after},
      ]
    } else {
      return [{action: 'wrapSelection', before, after: middle + after}]
    }
  } else if (singleParamParts) {
    const before = singleParamParts[1] ?? singleParamParts[3]
    const after = singleParamParts[2] ?? singleParamParts[4]

    if (selectedText.length) {
      // When there is a selection and only a single parameter, the selection should be used as the parameter
      // and the cursor placed at the end of the command
      return [{action: 'insert', text: before + selectedText + after}]
    } else {
      // When there is no selection and any number of parameters, the cursor should be placed within the
      // first parameter
      return [{action: 'wrapSelection', before, after}]
    }
  } else {
    // If there aren't parameters, the command should replace the selection, and the cursor should be placed
    // and the end of the command
    return [{action: 'insert', text: insertionText}]
  }
}
