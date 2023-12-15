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

export type SearchReplacePlugin = {
  // clears highlighted text and find state
  done: (keepEditorSelection?: boolean) => void
  // highlights all text occurences in RCE, do not call with blank string
  find: (text: string, matchCase?: boolean, wholeWord?: boolean, inSelection?: boolean) => number
  next: () => void
  prev: () => void
  // replaces current selection, does nothing if find has no state
  // forward moves selection to next (true) or previous (false)
  // returns true if more results, false if no more
  replace: (newText: string, forward?: boolean, all?: boolean) => boolean
}
