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

import {MARKER_ID, TRIGGER_CHAR} from './constants'

// characters allowed to proceed an "inline" @mention
export const spaceCharacters = [' ', '\u00A0', '\uFEFF']

/**
 * Returns true if a mention was initiated based on the selection. Otherwise,
 * returns false.
 *
 * @param {Selection} selection the selection object (tinymce Selection.getSel())
 *
 * @returns {boolean} Was a mention triggered?
 */
export default function mentionWasInitiated(selection, selectedNode) {
  const {anchorOffset, anchorNode} = selection
  const {wholeText} = anchorNode

  // If we are already in a selection, don't trigger another
  if (selectedNode?.id === MARKER_ID) return false

  // Is the trigger character being entered at the first position in a node?
  if (anchorOffset === 1 && anchorNode?.wholeText?.charAt(0) === TRIGGER_CHAR) return true

  // Check if it's possible that we have an "inline" mention. Return false if not
  if (!wholeText || anchorOffset < 2) return false

  // Do we have an "inline" mention (a " " character proceeds the trigger char)?
  const typedChar = wholeText[anchorOffset - 1] // The char just typed in
  const proceedingChar = wholeText[anchorOffset - 2]

  return typedChar === TRIGGER_CHAR && spaceCharacters.includes(proceedingChar)
}
