/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

const Helpers = {
  isValidImageType(mimeType) {
    switch (mimeType) {
      case 'image/jpeg':
      case 'image/gif':
      case 'image/png':
        return true
      default:
        return false
    }
  },

  extractInfoFromEvent(event) {
    let file = ''
    let type = ''
    if (event.type === 'change') {
      file = event.target.files[0]
      type = file.type
    } else {
      type = event.dataTransfer.files[0].type
      file = event.dataTransfer.files[0]
    }

    return {file, type}
  },
}
export default Helpers
