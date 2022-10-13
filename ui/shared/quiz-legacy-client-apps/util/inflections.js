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

export default {
  camelize(str, lowerFirst) {
    return (str || '').replace(/(?:^|[-_])(\w)/g, function (_, c, index) {
      if (index === 0 && lowerFirst) {
        return c ? c.toLowerCase() : ''
      } else {
        return c ? c.toUpperCase() : ''
      }
    })
  },

  underscore(str) {
    return str.replace(/([A-Z])/g, function ($1) {
      return '_' + $1.toLowerCase()
    })
  },
}
