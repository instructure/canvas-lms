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

export default function(linkHeader) {
  if (!linkHeader) {
    return []
  }
  const retVal = {}
  linkHeader
    .split(',')
    .map(partOfHeader => partOfHeader.split('; '))
    .forEach(link => {
      const myUrl = link[0].substring(1, link[0].length - 1)
      let urlRel = link[1].split('=')
      urlRel = urlRel[1]
      urlRel = urlRel.substring(1, urlRel.length - 1)

      retVal[urlRel] = myUrl
    })
  return retVal
}
