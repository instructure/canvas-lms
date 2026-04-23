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

import {useTransformedOutcomes} from '../useTransformedOutcomes'
import type {LMGBOutcomeReporting} from '../../types'
import type {StudentRollupData} from '@canvas/outcomes/react/types/rollup'

const baseRating = {
  description: 'Mastery',
  points: 3,
  mastery: true,
  color: '03893D',
}

const mockOutcome: LMGBOutcomeReporting = {
  id: '13',
  title: 'Outcome 1',
  display_name: 'O1',
  description: 'desc',
  friendly_description: undefined,
  mastery_points: 3,
  points_possible: 4,
  calculation_method: 'decaying_average',
  calculation_int: 65,
  ratings: [baseRating],
  alignments: ['assignment_14', 'assignment_17', 'rubric_10'],
}

const mockRollup = (count: number | undefined): StudentRollupData => ({
  studentId: '3',
  outcomeRollups: [
    {
      outcomeId: '13',
      score: 2.95,
      count,
      rating: baseRating,
    },
  ],
})

describe('useTransformedOutcomes', () => {
  it('uses the rollup count field for assessedAlignmentsCount', () => {
    const {outcomes} = useTransformedOutcomes([mockOutcome], [mockRollup(2)])
    expect(outcomes[0].assessedAlignmentsCount).toBe(2)
  })

  it('uses outcome alignments length for totalAlignmentsCount', () => {
    const {outcomes} = useTransformedOutcomes([mockOutcome], [mockRollup(2)])
    expect(outcomes[0].totalAlignmentsCount).toBe(3)
  })

  it('returns 0 for assessedAlignmentsCount when count is undefined', () => {
    const {outcomes} = useTransformedOutcomes([mockOutcome], [mockRollup(undefined)])
    expect(outcomes[0].assessedAlignmentsCount).toBe(0)
  })

  it('returns 0 for assessedAlignmentsCount when there is no rollup for the outcome', () => {
    const rollupWithDifferentOutcome: StudentRollupData = {
      studentId: '3',
      outcomeRollups: [
        {
          outcomeId: '999',
          score: 1,
          count: 5,
          rating: {...baseRating, color: `#${baseRating.color}`},
        },
      ],
    }
    const {outcomes} = useTransformedOutcomes([mockOutcome], [rollupWithDifferentOutcome])
    expect(outcomes[0].assessedAlignmentsCount).toBe(0)
  })

  it('returns empty array when there are no rollups', () => {
    const {outcomes} = useTransformedOutcomes([mockOutcome], [])
    expect(outcomes).toEqual([])
  })

  it('maps masteryScore from rollup score', () => {
    const {outcomes} = useTransformedOutcomes([mockOutcome], [mockRollup(2)])
    expect(outcomes[0].masteryScore).toBe(2.95)
  })

  it('sets masteryScore to null when outcome has no rollup entry', () => {
    const rollupWithDifferentOutcome: StudentRollupData = {
      studentId: '3',
      outcomeRollups: [{outcomeId: '999', score: 1, rating: {...baseRating, color: '#03893D'}}],
    }
    const {outcomes} = useTransformedOutcomes([mockOutcome], [rollupWithDifferentOutcome])
    expect(outcomes[0].masteryScore).toBeNull()
  })
})
