/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import GradingTypes from './grading-types'
import numberHelper from '@canvas/i18n/numberHelper'

const I18n = useI18nScope('conditional_release')

// stack overflow suggests this implementation
const isNumeric = n => {
  try {
    n = numberHelper.parse(n)
  } catch (e) {
    return false
  }
  return !Number.isNaN(Number(n)) && Number.isFinite(Number(n))
}

const checkBlank = s => {
  return s === null || s === '' || s.length === 0 ? I18n.t('must not be empty') : null
}

const checkNumeric = s => {
  return isNumeric(s) ? null : I18n.t('must be a number')
}

const checkBounds = (minScore, maxScore, score) => {
  score = numberHelper.parse(score)
  if (score > maxScore) {
    return I18n.t('number is too large')
  } else if (score < minScore) {
    return I18n.t('number is too small')
  } else {
    return null
  }
}

const checkInGradingScheme = (gradingScheme, score) => {
  return isNumeric(score) ? null : I18n.t('must provide valid letter grade')
}

const checkScoreOrder = (scores, previousErrors) => {
  return scores.map((score, index) => {
    if (previousErrors.get(index)) {
      return previousErrors.get(index)
    }
    score = numberHelper.parse(score)
    if (
      index > 0 &&
      !previousErrors.get(index - 1) &&
      score > numberHelper.parse(scores.get(index - 1))
    ) {
      return I18n.t('these scores are out of order')
    } else if (
      index + 1 < scores.size &&
      !previousErrors.get(index + 1) &&
      score < numberHelper.parse(scores.get(index + 1))
    ) {
      return I18n.t('these scores are out of order')
    } else {
      return null
    }
  })
}

// Rather than check the score at a single index, we
// check all the scores on each change, as an ordering
// error on one score might be resolved by a change
// to another
// An alternative approach is to keep track of error types,
// so we can clear just ordering errors.
export const validateScores = (scores, scoringInfo) => {
  const checks = [checkBlank]
  const gradingType = scoringInfo ? scoringInfo.get('grading_type') : null
  switch (gradingType) {
    case GradingTypes.letter_grade.key:
    case GradingTypes.gpa_scale.key:
      checks.push(
        checkInGradingScheme.bind(null, scoringInfo.get('grading_scheme')),
        checkBounds.bind(null, 0, 1.0)
      )
      break
    case GradingTypes.points.key:
    case GradingTypes.percent.key:
    default:
      checks.push(checkNumeric, checkBounds.bind(null, 0, 1.0))
      break
  }

  let errors = scores.map(score => {
    return checks.reduce((error, check) => {
      return error || check(score)
    }, null)
  })

  errors = checkScoreOrder(scores, errors)

  return errors
}
