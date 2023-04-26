/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

import $ from 'jquery'
// ported pluralizations from active_support/inflections.rb
// (except for cow -> kine, because nobody does that)
const skip = [
  'equipment',
  'information',
  'rice',
  'money',
  'species',
  'series',
  'fish',
  'sheep',
  'jeans',
]
const patterns = [
  [/person$/i, 'people'],
  [/man$/i, 'men'],
  [/child$/i, 'children'],
  [/sex$/i, 'sexes'],
  [/move$/i, 'moves'],
  [/(quiz)$/i, '$1zes'],
  [/^(ox)$/i, '$1en'],
  [/([m|l])ouse$/i, '$1ice'],
  [/(matr|vert|ind)(?:ix|ex)$/i, '$1ices'],
  [/(x|ch|ss|sh)$/i, '$1es'],
  [/([^aeiouy]|qu)y$/i, '$1ies'],
  [/(hive)$/i, '$1s'],
  [/(?:([^f])fe|([lr])f)$/i, '$1$2ves'],
  [/sis$/i, 'ses'],
  [/([ti])um$/i, '$1a'],
  [/(buffal|tomat)o$/i, '$1oes'],
  [/(bu)s$/i, '$1ses'],
  [/(alias|status)$/i, '$1es'],
  [/(octop|vir)us$/i, '$1i'],
  [/(ax|test)is$/i, '$1es'],
  [/s$/i, 's'],
] as const

const pluralize = function (string: string) {
  string = string || ''
  if ($.inArray(string, skip) > 0) {
    return string
  }
  for (let i = 0; i < patterns.length; i++) {
    const pair = patterns[i]
    if (string.match(pair[0])) {
      return string.replace(pair[0], pair[1])
    }
  }
  return string + 's'
}

pluralize.withCount = function (count: number, string: string) {
  return '' + count + ' ' + (count === 1 ? string : pluralize(string))
}

export default pluralize
