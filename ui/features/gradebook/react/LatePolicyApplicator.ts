// @ts-nocheck
/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import ScoreToGradeHelper from './shared/helpers/ScoreToGradeHelper'
import round from '@canvas/round'
import type {Submission} from '../../../api.d'

const equivalentToNull = [undefined, null, '', 0]
const intervalTypes = ['day', 'hour']

function equivalent(a, b) {
  return a === b || (equivalentToNull.includes(a) && equivalentToNull.includes(b))
}

function isPositive(val: number | null) {
  if (Number.isNaN(val)) {
    return false
  }

  return (val || 0) > 0
}

function getEnteredScore(score, pointsDeducted) {
  if (score == null) {
    return score
  }

  return score + (pointsDeducted || 0)
}

function changeSubmission(submission, score, grade, pointsDeducted, assignment, gradingScheme) {
  const changed = !(
    equivalent(score, submission.score) &&
    equivalent(grade, submission.grade) &&
    equivalent(pointsDeducted, submission.points_deducted)
  )

  const enteredScore = getEnteredScore(score, pointsDeducted)
  const enteredGrade = ScoreToGradeHelper.scoreToGrade(enteredScore, assignment, gradingScheme)

  submission.points_deducted = pointsDeducted
  submission.score = score
  submission.grade = grade
  submission.entered_score = enteredScore
  submission.entered_grade = enteredGrade

  return changed
}

function submissionIntervalsLate(submission, intervalType) {
  if (!submission.late) {
    return 0
  }

  if (!intervalTypes.includes(intervalType)) {
    throw new Error(`Unknown intervalType '${intervalType}'`)
  }

  const hoursLate = submission.seconds_late / 3600
  const daysLate = hoursLate / 24

  return Math.ceil(intervalType === 'day' ? daysLate : hoursLate)
}

function latePenalty(submission: Submission, assignment, latePolicy) {
  const {
    lateSubmissionDeduction,
    lateSubmissionDeductionEnabled,
    lateSubmissionMinimumPercent,
    lateSubmissionMinimumPercentEnabled,
    lateSubmissionInterval,
  } = latePolicy

  if (submission.points_deducted !== null && !lateSubmissionDeductionEnabled) {
    return submission.points_deducted
  }

  if (!lateSubmissionDeductionEnabled || !isPositive(submission.entered_score || 0)) {
    return 0
  }

  const intervalsLate = submissionIntervalsLate(submission, lateSubmissionInterval)
  const minimumPercent = lateSubmissionMinimumPercentEnabled ? lateSubmissionMinimumPercent : 0
  const rawScorePercent = ((submission.entered_score || 0) * 100) / assignment.points_possible
  const maximumDeduct = Math.max(rawScorePercent - minimumPercent, 0)
  const latePercentDeduct = lateSubmissionDeduction * intervalsLate

  return (Math.min(latePercentDeduct, maximumDeduct) * assignment.points_possible) / 100
}

function missingScore(submission, assignment, latePolicy) {
  const {missingSubmissionDeductionEnabled, missingSubmissionDeduction} = latePolicy

  if (!missingSubmissionDeductionEnabled) {
    return submission.entered_score
  }

  return ((100 - missingSubmissionDeduction) * assignment.points_possible) / 100
}

function processLateSubmission(submission, assignment, gradingScheme, latePolicy) {
  const pointsDeducted = round(latePenalty(submission, assignment, latePolicy), 2)
  const score =
    submission.entered_score != null ? submission.entered_score - (pointsDeducted || 0) : null
  const grade = ScoreToGradeHelper.scoreToGrade(score, assignment, gradingScheme)

  return changeSubmission(submission, score, grade, pointsDeducted, assignment, gradingScheme)
}

function processMissingSubmission(submission, assignment, gradingScheme, latePolicy) {
  const score = missingScore(submission, assignment, latePolicy)
  const grade = ScoreToGradeHelper.scoreToGrade(score, assignment, gradingScheme)

  return changeSubmission(submission, score, grade, 0, assignment, gradingScheme)
}

const LatePolicyApplicator = {
  processSubmission(submission, assignment, gradingScheme, latePolicy) {
    if (assignment.grading_type === 'pass_fail' || !isPositive(assignment.points_possible)) {
      return false
    }

    let changed = false

    if (submission.late) {
      changed = processLateSubmission(submission, assignment, gradingScheme, latePolicy)
    } else if (submission.missing && submission.score == null && submission.grade == null) {
      changed = processMissingSubmission(submission, assignment, gradingScheme, latePolicy)
    }

    return changed
  },
}

export default LatePolicyApplicator
