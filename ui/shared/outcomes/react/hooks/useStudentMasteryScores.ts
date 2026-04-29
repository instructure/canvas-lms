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

import {useMemo} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Outcome, StudentRollupData, Student} from '../types/rollup'

const I18n = createI18nScope('LearningMasteryGradebook')

export interface MasteryBucket {
  name: string
  iconURL: string
  count: number
}

export interface StudentMasteryScores {
  masteryRelativeAverage: number | null
  grossAverage: number | null
  averageIconURL: string
  averageText: string
  buckets: {
    [key: string]: MasteryBucket
  }
}

export const pickBucketForScore = (
  score: number | null,
  buckets: StudentMasteryScores['buckets'],
): MasteryBucket => {
  if (score === null) return buckets.no_evidence
  if (score > 0) return buckets.exceeds_mastery
  if (score === 0) return buckets.mastery
  if (score < -1) return buckets.remediation
  if (score < 0) return buckets.near_mastery
  return buckets.no_evidence
}

export const calculateScores = (
  outcomes: Outcome[],
  rollups: StudentRollupData[],
  student: Student,
): StudentMasteryScores => {
  const result: StudentMasteryScores = {
    masteryRelativeAverage: null,
    grossAverage: null,
    averageIconURL: '',
    averageText: '',
    buckets: {
      no_evidence: {
        name: I18n.t('No Evidence'),
        iconURL: '/images/outcomes/no_evidence.svg',
        count: 0,
      },
      remediation: {
        name: I18n.t('Remediation'),
        iconURL: '/images/outcomes/remediation.svg',
        count: 0,
      },
      near_mastery: {
        name: I18n.t('Near Mastery'),
        iconURL: '/images/outcomes/near_mastery.svg',
        count: 0,
      },
      mastery: {name: I18n.t('Mastery'), iconURL: '/images/outcomes/mastery.svg', count: 0},
      exceeds_mastery: {
        name: I18n.t('Exceeds Mastery'),
        iconURL: '/images/outcomes/exceeds_mastery.svg',
        count: 0,
      },
    },
  }

  const userOutcomeRollups = rollups?.find(r => r.studentId === student.id)?.outcomeRollups || []

  if (outcomes?.length)
    result.buckets.no_evidence.count = outcomes.length - userOutcomeRollups.length

  let grossTotalScore = 0
  let masteryRelativeTotalScore = 0
  let withResultsCount = 0

  userOutcomeRollups.forEach(rollup => {
    const outcome = outcomes?.find(o => o.id === rollup.outcomeId)
    if (!outcome) return
    const masteryScore = rollup.rating.points - outcome.mastery_points
    const bucket = pickBucketForScore(masteryScore, result.buckets)
    bucket.count++
    masteryRelativeTotalScore += masteryScore
    grossTotalScore += rollup.rating.points
    withResultsCount++
  })

  if (withResultsCount > 0) {
    result.masteryRelativeAverage = masteryRelativeTotalScore / withResultsCount
    result.grossAverage = grossTotalScore / withResultsCount
  }

  const averageBucket = pickBucketForScore(result.masteryRelativeAverage, result.buckets)
  result.averageIconURL = averageBucket.iconURL
  result.averageText = averageBucket.name

  return result
}

interface UseStudentMasteryScoresProps {
  student: Student | null
  outcomes: Outcome[]
  rollups: StudentRollupData[]
}

export const useStudentMasteryScores = ({
  student,
  outcomes,
  rollups,
}: UseStudentMasteryScoresProps): StudentMasteryScores | null => {
  return useMemo(() => {
    if (!student) return null
    return calculateScores(outcomes, rollups, student)
  }, [student, outcomes, rollups])
}
