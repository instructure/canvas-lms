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
import type {RubricAssessmentData, RubricCriterion, RubricRating} from '../../types/rubric'

import {useScope as createI18nScope} from '@canvas/i18n'
const I18n = createI18nScope('enhanced-rubrics-assessment')

export const htmlEscapeCriteriaLongDescription = (criteria: RubricCriterion) => {
  const {longDescription} = criteria

  return {
    __html: longDescription ?? '',
  }
}

export const escapeNewLineText = (text?: string) => {
  return {
    __html: htmlEscape(text ?? '').replace(/\n/g, '<br />'),
  }
}

export const rangingFrom = (ratings: RubricRating[], index: number, ratingOrder?: string) => {
  const previousRatingPoints = ratings[index - 1]?.points
  const previousPointModifier = getAdjustedDecimalRatingModifier(previousRatingPoints)
  const nextRatingPoints = ratings[index + 1]?.points
  const nextPointModifier = getAdjustedDecimalRatingModifier(nextRatingPoints)

  if (ratingOrder === 'ascending') {
    return index > 0
      ? roundToTwoDecimalPlaces(previousRatingPoints + previousPointModifier)
      : undefined
  }

  return index < ratings.length - 1
    ? roundToTwoDecimalPlaces(nextRatingPoints + nextPointModifier)
    : undefined
}

const getAdjustedDecimalRatingModifier = (points: number) => {
  if (points == null) {
    return 0
  }
  const twoDecimalRegex = /^\d+\.\d{2}$/
  return twoDecimalRegex.test(points.toString()) ? 0.01 : 0.1
}

const roundToTwoDecimalPlaces = (num: number) => {
  return Math.round(num * 100) / 100
}

export const findCriterionMatchingRatingIndex = (
  ratings: RubricRating[],
  points?: number,
  criterionUseRange = false,
): number => {
  if (points == null) {
    return -1
  }
  return criterionUseRange
    ? ratings.findLastIndex(rating => rating.points >= points)
    : ratings.findIndex(rating => rating.points === points)
}

export const findCriterionMatchingRatingId = (
  ratings: RubricRating[],
  criterionUseRange: boolean,
  rubricAssessmentData?: RubricAssessmentData,
) => {
  const {id, points} = rubricAssessmentData || {}
  if (points == null) {
    return undefined
  }

  return ratings.find(rating => rating.id === id && (criterionUseRange || rating.points === points))
    ?.id
}

export const rubricSelectedAriaLabel = (isSelected: boolean, isSelfAssessmentSelected: boolean) => {
  if (isSelected && isSelfAssessmentSelected) {
    return I18n.t('Selected and Self Assessment')
  }

  if (isSelected) {
    return I18n.t('Selected')
  }

  if (isSelfAssessmentSelected) {
    return I18n.t('Self Assessment')
  }

  return ''
}
