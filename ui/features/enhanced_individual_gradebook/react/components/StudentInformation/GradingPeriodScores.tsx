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
import type {GradingPeriodGrade, DeprecatedGradingScheme} from '@canvas/grading/grading.d'
import type {GradingPeriodSet} from '../../../../../api.d'
import RowScore from './RowScore'

type Props = {
  gradingPeriodId: string
  gradingPeriods: {
    [periodId: string]: GradingPeriodGrade
  }
  gradingPeriodSet: GradingPeriodSet
  gradingScheme?: DeprecatedGradingScheme | null
  includeUngradedAssignments: boolean
}
export function GradingPeriodScores({
  gradingPeriodId,
  gradingPeriods,
  gradingPeriodSet,
  gradingScheme,
  includeUngradedAssignments,
}: Props) {
  const matchingGradingPeriod = gradingPeriodSet.grading_periods.find(
    ({id}) => id === gradingPeriodId
  )

  if (!matchingGradingPeriod) {
    return null
  }

  const {title, weight} = matchingGradingPeriod
  const {final: gradingPeriodFinal, current: gradingPeriodCurrent} = gradingPeriods[gradingPeriodId]
  const gradingPeriodGradeToDisplay = includeUngradedAssignments
    ? gradingPeriodFinal
    : gradingPeriodCurrent
  const {score, possible} = gradingPeriodGradeToDisplay

  return (
    <RowScore
      gradingScheme={gradingScheme}
      name={title}
      possible={possible}
      score={score}
      weight={weight}
    />
  )
}
