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

import {StudentRollupData} from '@canvas/outcomes/react/types/rollup'

import type {LMGBOutcomeReporting, MasteryLevel, Outcome} from '../types'
import {getTagIcon} from '@canvas/outcomes/react/utils/icons'

const transformOutcomeData = (
  outcomes: LMGBOutcomeReporting[],
  rollups: StudentRollupData[],
): Outcome[] => {
  const outcomesList = outcomes
  const studentRollup = rollups?.[0]

  if (!studentRollup) return []

  return outcomesList.map(outcome => {
    const score = studentRollup.outcomeRollups.find(o => o.outcomeId === outcome.id)?.score
    const assessedAlignmentsCount =
      studentRollup.outcomeRollups.filter(o => o.outcomeId === outcome.id).length || 0
    const totalAlignmentsCount = outcome.alignments?.length || 0
    const masteryScore = score ?? null

    // static score handling will be fixed in https://instructure.atlassian.net/browse/OUTC-504
    const masteryLevel = getTagIcon(score, outcome.mastery_points) as MasteryLevel

    return {
      id: outcome.id,
      code: outcome.display_name || outcome.title,
      name: outcome.title,
      description: outcome.friendly_description || outcome.description || '',
      assessedAlignmentsCount,
      totalAlignmentsCount,
      masteryScore,
      masteryLevel,
    }
  })
}

export const useTransformedOutcomes = (
  outcomes: LMGBOutcomeReporting[],
  rollups: StudentRollupData[],
): {outcomes: Outcome[]} => {
  const result = transformOutcomeData(outcomes, rollups)

  return {outcomes: result}
}
