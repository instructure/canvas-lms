/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import I18n from 'i18nObj'

// this is like $.extend(true, destination, source) but much faster and it mutates
function fastMerge(destination, source) {
  const keys = Object.keys(source)
  for (let i = 0, l = keys.length; i < l; i++) {
    const key = keys[i]
    const val = source[key]
    if (typeof destination[key] === 'object') {
      fastMerge(destination[key], val)
    } else {
      destination[key] = val
    }
  }
  return destination
}

export default function mergeI18nTranslations(newStrings) {
  fastMerge(I18n.translations, newStrings)
}
