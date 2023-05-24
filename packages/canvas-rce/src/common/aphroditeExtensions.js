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

const aphrodite = require('aphrodite')

function pseudochild(selector, baseSelector, generateSubtreeStyles) {
  const regex = /^#:(?:\w|-)+\s{1}\w+$/im
  if (!selector.match(regex)) {
    return null
  }

  const pseudo = selector.slice(1).split(' ')[0]
  const parentsel = '.' + selector.split(' ')[1]
  return generateSubtreeStyles(baseSelector + pseudo + ' ' + parentsel)
}

const myExtension = {selectorHandler: pseudochild}

module.exports = aphrodite.StyleSheet.extend([myExtension])
