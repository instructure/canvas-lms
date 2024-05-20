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

export function replaceOneTag(text: string, name: string, value?: string) {
  if (!text) {
    return text
  }
  name = (name || '').toString()
  value = (value || '').toString().replace(/\s/g, '+')
  const itemExpression = new RegExp('(%7B|{){2}[\\s|%20|+]*' + name + '[\\s|%20|+]*(%7D|}){2}', 'g')
  return text.replace(itemExpression, value)
}

export default function replaceTags(
  text: string,
  mapping_or_name: Record<string, string | undefined> | string,
  maybe_value?: string
): string {
  if (typeof mapping_or_name === 'object') {
    for (const name in mapping_or_name) {
      text = replaceOneTag(text, name, mapping_or_name[name])
    }
    return text
  } else {
    return replaceOneTag(text, mapping_or_name, maybe_value)
  }
}
