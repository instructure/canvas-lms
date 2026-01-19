/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {Student, StudentRollupData} from '@canvas/outcomes/react/types/rollup'
import {type ContributingScoresManager} from '@canvas/outcomes/react/hooks/useContributingScores'

/**
 * Extracts scores for a specific outcome from student rollup data
 * @param rollups - Array of student rollup data
 * @param outcomeId - The ID of the outcome to get scores for
 * @returns Array of scores (or undefined) for each student
 *
 *  TODO: fetch aggregate scores for outcome and alignments for all pages
 *  https://instructure.atlassian.net/browse/OUTC-534
 */
export const getScoresForOutcome = (
  rollups: StudentRollupData[],
  outcomeId: string | number,
): (number | undefined)[] => {
  return rollups.map(rollup => {
    const outcomeRollup = rollup.outcomeRollups.find(
      or => or.outcomeId.toString() === outcomeId.toString(),
    )
    return outcomeRollup?.score
  })
}

/**
 * Extracts scores for a specific alignment within an outcome
 * @param contributingScores - Contributing scores manager
 * @param students - Array of students
 * @param outcomeId - The ID of the outcome
 * @param alignmentId - The ID of the alignment to get scores for
 * @returns Array of scores (or undefined) for each student for the specific alignment
 */
export const getScoresForAlignment = (
  contributingScores: ContributingScoresManager,
  students: Student[],
  outcomeId: string | number,
  alignmentId: string,
): (number | undefined)[] => {
  const contributingScoreForOutcome = contributingScores.forOutcome(outcomeId)
  if (!contributingScoreForOutcome.data) return []

  return students.map(student => {
    const scoresForUser = contributingScoreForOutcome.scoresForUser(student.id)
    const alignment = contributingScoreForOutcome.alignments?.find(
      a => a.alignment_id === alignmentId,
    )
    if (!alignment) return undefined

    const alignmentIndex = contributingScoreForOutcome.alignments?.indexOf(alignment) ?? -1
    return scoresForUser[alignmentIndex]?.score
  })
}
