/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React from 'react'
import type {DeprecatedGradingScheme} from '@canvas/grading/grading.d'
import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'
import {useScope as useI18nScope} from '@canvas/i18n'
import {getLetterGrade, scoreToPercentage, scoreToScaledPoints} from '../../../utils/gradebookUtils'

const I18n = useI18nScope('enhanced_individual_gradebook')

type Props = {
  name: string
  score?: number
  possible?: number
  weight?: number | null
  gradingScheme?: DeprecatedGradingScheme | null
}
export default function RowScore({gradingScheme, name, possible, score, weight}: Props) {
  const percentScore = scoreToPercentage(score, possible, 1)

  const isPercentInvalid = Number.isNaN(Number(percentScore))

  let scoreText

  let displayAsScaledPoints = false
  if (gradingScheme) {
    displayAsScaledPoints = gradingScheme.pointsBased
    const scalingFactor = gradingScheme.scalingFactor

    if (displayAsScaledPoints && possible) {
      const scaledPossible = I18n.n(scalingFactor, {
        precision: 1,
      })
      const scaledScore = I18n.n(scoreToScaledPoints(score || 0, possible, scalingFactor), {
        precision: 1,
      })

      scoreText = `${scaledScore} / ${scaledPossible}`
    } else {
      scoreText = isPercentInvalid ? '-' : `${percentScore}% (${score} / ${possible})`
    }
  }

  const letterGradeScore = isPercentInvalid
    ? '-'
    : gradingScheme
    ? GradeFormatHelper.replaceDashWithMinus(getLetterGrade(possible, score, gradingScheme.data))
    : '-'

  const weightText = weight ? I18n.n(weight, {percentage: true}) : '-'

  return (
    <tr>
      <th>{name}</th>
      <td data-testid="subtotal-grade">{scoreText}</td>
      <td>{letterGradeScore}</td>
      <td>{weightText}</td>
    </tr>
  )
}
