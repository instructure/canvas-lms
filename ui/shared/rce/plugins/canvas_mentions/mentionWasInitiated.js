/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

// characters allowed to proceed an "inline" @mention
const spaceCharacters = [' ', '\u00A0']

/**
 * Returns true if a mention was initiated based on the selection. Otherwise,
 * returns false.
 *
 * @param {Selection} selection the selection object (tinymce Selection.getSel())
 * @param {string} triggerChar (defaults to "@")
 *
 * @returns {boolean} Was a mention triggered?
 */
export default function mentionWasInitiated(selection, triggerChar = '@') {
  const {anchorOffset, anchorNode} = selection
  const {wholeText} = anchorNode

  // Is the trigger character being entered at the first position in a node?
  if (anchorOffset === 1 && anchorNode?.wholeText?.charAt(0) === triggerChar) return true

  // Check if it's possible that we have an "inline" mention. Return false if not
  if (!wholeText || anchorOffset < 2) return false

  // Do we have an "inline" mention (a " " character proceeds the trigger char)?
  const typedChar = wholeText[anchorOffset - 1] // The char just typed in
  const proceedingChar = wholeText[anchorOffset - 2]

  return typedChar === triggerChar && spaceCharacters.includes(proceedingChar)
}
