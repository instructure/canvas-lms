/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import htmlEscape from '@instructure/html-escape'
import type {RubricCriterion, RubricRating} from '../../types/rubric'

export const htmlEscapeCriteriaLongDescription = (criteria: RubricCriterion) => {
  const {longDescription} = criteria

  return {
    __html: longDescription ?? '',
  }
}

export const escapeNewLineText = (text: string) => {
  return {
    __html: htmlEscape(text ?? '').replace(/\n/g, '<br />'),
  }
}

export const rangingFrom = (ratings: RubricRating[], index: number, ratingOrder?: string) => {
  if (ratingOrder === 'ascending') {
    return index > 0 ? ratings[index - 1].points + 0.1 : undefined
  }
  return index < ratings.length - 1 ? ratings[index + 1].points + 0.1 : undefined
}

export const findCriterionMatchingRatingIndex = (
  ratings: RubricRating[],
  points?: number,
  criterionUseRange = false
): number => {
  if (points == null) {
    return -1
  }
  return criterionUseRange
    ? ratings.findLastIndex(rating => rating.points >= points)
    : ratings.findIndex(rating => rating.points === points)
}
