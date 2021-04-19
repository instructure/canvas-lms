/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

// This is a temporary patch until the All Files panel
// is rewritten to use the files actions that query
// data from the RCS, but still the CanvasContentTray
// know when the FileBrowser is actively querying
// so we can disable the search box in the Filter

export const ALL_FILES_LOADING = 'ALL_FILES_LOADING'

export function allFilesLoading(isLoading) {
  return {type: ALL_FILES_LOADING, payload: isLoading}
}
