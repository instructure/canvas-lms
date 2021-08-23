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

export const svgUrl = (points, masteryAt) => {
  return `/images/outcomes/${getTagIcon(points, masteryAt)}.svg`
}

const getTagIcon = (points, masteryAt) => {
  if (points == null) {
    return 'unassessed'
  }
  const score = points - masteryAt
  switch (true) {
    case score > 0:
      return 'star'
    case score === 0:
      return 'mastery'
    case score > -1 * masteryAt:
      return 'near_mastery'
    default:
      return 'below_mastery'
  }
}
