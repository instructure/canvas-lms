/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {Rating} from '../types/rollup'

/**
 * Finds the appropriate rating for a given score from a list of ratings.
 * Assumes ratings are sorted in descending order by points.
 *
 * Returns the first rating where the score meets or exceeds the rating's point threshold.
 * If no rating matches, returns the lowest rating as a fallback.
 *
 * @param ratings - Array of ratings sorted in descending order by points
 * @param score - The score to find a rating for
 * @returns The matching rating, or the lowest rating if no match is found
 */
export const findRating = (ratings: Rating[], score: number): Rating => {
  return ratings.find(r => score >= r.points) ?? ratings[ratings.length - 1]
}
