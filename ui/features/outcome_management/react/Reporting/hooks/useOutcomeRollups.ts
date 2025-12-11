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

import {MOCK_API_OUTCOMES} from '../studentOutcomesTableMock'

import type {
  LMGBRating,
  LMGBScoreReporting,
  MasteryLevel,
  Outcome,
  RollupsResponseReporting,
} from '../types'

/**
 * Finds the appropriate rating for a given score from a list of ratings.
 * Assumes ratings are sorted in descending order by points.
 *
 * Returns the first rating where the score meets or exceeds the rating's point threshold.
 * If no rating matches, returns the lowest rating as a fallback.
 */
const findRating = (ratings: LMGBRating[], score: number): LMGBRating => {
  return ratings.find(r => score >= r.points) ?? ratings[ratings.length - 1]
}

const getMasteryLevelFromRating = (rating: LMGBRating | null): MasteryLevel => {
  if (!rating) return 'unassessed'

  const lowerCaseDescription = rating.description?.toLowerCase() || ''

  if (lowerCaseDescription.includes('exceeds')) return 'exceeds_mastery'
  if (lowerCaseDescription.includes('near')) return 'near_mastery'
  if (lowerCaseDescription.includes('below')) return 'remediation'
  if (lowerCaseDescription.includes('mastery')) return 'mastery'

  return 'remediation'
}

const transformOutcomeData = (apiResponse: RollupsResponseReporting): Outcome[] => {
  const {rollups, linked} = apiResponse
  const outcomesList = linked?.outcomes || []
  const studentRollup = rollups?.[0]

  if (!studentRollup) return []

  const scoresMap: Record<string, LMGBScoreReporting> = {}
  studentRollup.scores?.forEach(scoreData => {
    const outcomeId = scoreData.links?.outcome
    if (outcomeId) {
      scoresMap[outcomeId] = {
        ...scoreData,
      }
    }
  })

  return outcomesList.map(outcome => {
    const scoreData = scoresMap[outcome.id]
    const assessedAlignmentsCount = scoreData?.count || 0
    const totalAlignmentsCount = outcome.alignments?.length || 0
    const masteryScore = scoreData?.score

    const rating = scoreData ? findRating(outcome.ratings, scoreData.score || 0) : null
    const masteryLevel = getMasteryLevelFromRating(rating)

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

export const useOutcomeRollups = (): {outcomes: Outcome[]} => {
  const apiOutcomes = MOCK_API_OUTCOMES

  const outcomes = transformOutcomeData(apiOutcomes)

  return {outcomes}
}
