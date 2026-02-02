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

export const htmlEscapeCriteriaLongDescription = (longDescription = '') => {
  const decodedText = decodeHtmlEntities(longDescription)

  return {
    __html: decodedText,
  }
}

export const fullyDecodeHtmlEntities = (text?: string): string => {
  if (!text) {
    return ''
  }

  let decoded = text || ''
  let previous = ''
  // Keep decoding while entities remain (handles double/triple encoding)
  while (decoded !== previous && decoded.includes('&')) {
    previous = decoded
    decoded = decodeHtmlEntities(decoded)
  }
  return decoded
}

export const decodeHtmlEntities = (text?: string): string => {
  if (!text) {
    return ''
  }
  const textarea = document.createElement('textarea')
  textarea.innerHTML = text
  return textarea.value
}

export const escapeNewLineText = (text?: string) => {
  return {
    __html: htmlEscape(text ?? '').replace(/\n/g, '<br />'),
  }
}

export const rangingFrom = (
  ratings: RubricRating[],
  index: number,
  ratingOrder?: string,
  includeZeroFrom?: boolean,
) => {
  const previousRatingPoints = ratings[index - 1]?.points
  const previousPointModifier = getAdjustedDecimalRatingModifier(previousRatingPoints)
  const nextRatingPoints = ratings[index + 1]?.points
  const nextPointModifier = getAdjustedDecimalRatingModifier(nextRatingPoints)
  const currentRatingPoints = ratings[index]?.points

  if (ratingOrder === 'ascending') {
    if (currentRatingPoints === previousRatingPoints) {
      return undefined
    }

    if (includeZeroFrom && index === 0) {
      return 0
    }

    return index > 0
      ? roundToTwoDecimalPlaces(previousRatingPoints + previousPointModifier)
      : undefined
  }

  if (currentRatingPoints === nextRatingPoints) {
    return undefined
  }

  if (includeZeroFrom && index === ratings.length - 1) {
    return 0
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

export const isRubricComplete = ({
  criteria,
  isFreeFormCriterionComments,
  hidePoints,
  rubricAssessment,
}: {
  criteria: RubricCriterion[]
  isFreeFormCriterionComments: boolean
  hidePoints: boolean
  rubricAssessment: RubricAssessmentData[]
}): boolean => {
  if (criteria.length !== rubricAssessment.length) {
    return false
  }

  return rubricAssessment.every(criterion => {
    const hasComments = criterion.comments?.trim().length

    // If we're hiding points and using free-form comments,
    // we need to ensure comments are present
    if (hidePoints && isFreeFormCriterionComments) {
      return hasComments
    }

    const points = criterion.points
    const validPoints = typeof points === 'number' && !Number.isNaN(points)
    const hasPoints = points !== undefined
    return hasPoints && validPoints
  })
}
