/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import uuid from 'uuid/v1'

export const convertRatings = rawRatings => {
  let masteryPoints
  const ratings = rawRatings.map(({description, points, mastery}) => {
    const pointsFloat = parseFloat(points)
    if (mastery) masteryPoints = pointsFloat
    return {description, points: pointsFloat}
  })
  return {masteryPoints, ratings}
}

export const prepareRatings = (ratings, masteryPoints) =>
  (ratings || []).map(({description, points}) => ({
    description,
    points,
    mastery: Number(points) === Number(masteryPoints),
    key: uuid()
  }))
