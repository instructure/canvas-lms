// @ts-nocheck
/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import {divide, sum, sumBy} from './GradeCalculationHelper'
import type {Assignment, AssignmentGroup} from '../../api.d'
import type {AggregateGrade, AssignmentGroupGrade, SubmissionGradeCriteria} from './grading.d'

type DroppableSubmission = {
  total: number
  drop?: boolean
  assignment_id?: string
}

function partition(collection, partitionFn) {
  return collection.reduce(
    (result, current) => {
      const index = partitionFn(current) ? 0 : 1
      result[index].push(current)
      return result
    },
    [[], []]
  )
}

function parseScore(score: string | number | null) {
  const result = parseFloat(String(score))
  return result && Number.isFinite(result) ? result : 0
}

function sortPairsDescending(
  [scoreA, submissionA]: [number, {submission: SubmissionGradeCriteria}],
  [scoreB, submissionB]: [number, {submission: SubmissionGradeCriteria}]
) {
  const scoreDiff = scoreB - scoreA
  if (scoreDiff !== 0) {
    return scoreDiff
  }
  // To ensure stable sorting, use the assignment id as a secondary sort.
  // @ts-expect-error
  return submissionA.submission.assignment_id - submissionB.submission.assignment_id
}

function sortPairsAscending(
  [scoreA, submissionA]: [number, {submission: SubmissionGradeCriteria}],
  [scoreB, submissionB]: [number, {submission: SubmissionGradeCriteria}]
) {
  const scoreDiff = scoreA - scoreB
  if (scoreDiff !== 0) {
    return scoreDiff
  }
  // To ensure stable sorting, use the assignment id as a secondary sort.
  // @ts-expect-error
  return submissionA.submission.assignment_id - submissionB.submission.assignment_id
}

function sortSubmissionsAscending(submissionA, submissionB) {
  const scoreDiff = submissionA.score - submissionB.score
  if (scoreDiff !== 0) {
    return scoreDiff
  }
  // To ensure stable sorting, use the assignment id as a secondary sort.
  return submissionA.submission.assignment_id - submissionB.submission.assignment_id
}

function getSubmissionGrade({score, total}: {score: number; total: number}) {
  return score / total
}

function estimateQHigh(
  pointed: {total: number; score: number}[],
  unpointed: {score: number}[],
  grades: number[]
) {
  if (unpointed.length > 0) {
    const pointsPossible = sumBy(pointed, 'total')
    const bestPointedScore = Math.max(pointsPossible, sumBy(pointed, 'score'))
    const unpointedScore = sumBy(unpointed, 'score')
    return (bestPointedScore + unpointedScore) / pointsPossible
  }

  return grades[grades.length - 1]
}

function buildBigF(keepCount: number, cannotDrop: DroppableSubmission[], sortAsc) {
  return function bigF(q: number, submissions: SubmissionGradeCriteria[]) {
    const ratedScores = submissions.map(submission => [
      submission.score - q * submission.total,
      submission,
    ])
    const rankedScores = ratedScores.sort(sortAsc ? sortPairsAscending : sortPairsDescending)
    const keptScores = rankedScores.slice(0, keepCount)
    const qKept = sumBy(keptScores, ([score]) => score)
    const keptSubmissions = keptScores.map(([_score, submission]) => submission)
    const qCannotDrop = sumBy(
      cannotDrop,
      // @ts-expect-error
      (submission: SubmissionGradeCriteria) => submission.score - q * submission.total
    )
    return [qKept + qCannotDrop, keptSubmissions]
  }
}

function setUpGrades(pointed, unpointed) {
  const grades = pointed.map(getSubmissionGrade).sort()
  const qHigh = estimateQHigh(pointed, unpointed, grades)
  const qLow = grades[0]
  const qMid = (qLow + qHigh) / 2

  return [qHigh, qLow, qMid]
}

function keepHelper(submissions, initialKeepCount, sortAsc, cannotDrop, maxTotal) {
  const keepCount = Math.max(1, initialKeepCount)

  if (submissions.length <= keepCount) {
    return submissions
  }

  const allSubmissionData = [...submissions, ...cannotDrop]
  const [unpointed, pointed] = partition(
    allSubmissionData,
    submissionDatum => submissionDatum.total === 0
  )

  let [qHigh, qLow, qMid] = setUpGrades(pointed, unpointed)

  const bigF = buildBigF(keepCount, cannotDrop, sortAsc)

  let [x, submissionsToKeep] = bigF(qMid, submissions)
  const threshold = 1 / (2 * keepCount * maxTotal ** 2)
  while (qHigh - qLow >= threshold) {
    if (x < 0) {
      qHigh = qMid
    } else {
      qLow = qMid
    }
    qMid = (qLow + qHigh) / 2
    if (qMid === qHigh || qMid === qLow) {
      break
    }

    ;[x, submissionsToKeep] = bigF(qMid, submissions)
  }

  return submissionsToKeep
}

function dropPointed(
  droppableSubmissionData: DroppableSubmission[],
  cannotDrop: DroppableSubmission[],
  keepHighest: number,
  keepLowest: number
) {
  const totals = droppableSubmissionData.map(submission => submission.total)
  const maxTotal = Math.max(...totals)

  const submissionsWithLowestDropped = keepHelper(
    droppableSubmissionData,
    keepHighest,
    false, // sort descending
    cannotDrop,
    maxTotal
  )
  return keepHelper(
    submissionsWithLowestDropped,
    keepLowest,
    true, // sort ascending
    cannotDrop,
    maxTotal
  )
}

function dropUnpointed(submissions, keepHighest, keepLowest) {
  const sortedSubmissions = submissions.sort(sortSubmissionsAscending)
  return sortedSubmissions.slice(-keepHighest).slice(0, keepLowest)
}

// I am not going to pretend that this code is understandable.
//
// The naive approach to dropping the lowest grades (calculate the
// grades for each combination of assignments and choose the set which
// results in the best overall score) is obviously too slow.
//
// This approach is based on the algorithm described in "Dropping Lowest
// Grades" by Daniel Kane and Jonathan Kane. Please see that paper for
// a full explanation of the math.
// (http://cseweb.ucsd.edu/~dakane/droplowest.pdf)
function dropAssignments(
  allSubmissionData: DroppableSubmission[],
  rules: AssignmentGroup['rules'] = {}
): DroppableSubmission[] {
  let dropLowest = rules.drop_lowest || 0
  let dropHighest = rules.drop_highest || 0
  const neverDropIds = rules.never_drop || []

  if (!(dropLowest || dropHighest)) {
    return allSubmissionData
  }

  let cannotDrop: DroppableSubmission[] = []
  let droppableSubmissionData: DroppableSubmission[] = allSubmissionData
  if (neverDropIds.length > 0) {
    ;[cannotDrop, droppableSubmissionData] = partition(allSubmissionData, submission =>
      neverDropIds.includes(submission.submission.assignment_id)
    )
  }

  if (droppableSubmissionData.length === 0) {
    return cannotDrop
  }

  dropLowest = Math.min(dropLowest, droppableSubmissionData.length - 1)
  dropHighest = dropLowest + dropHighest >= droppableSubmissionData.length ? 0 : dropHighest

  const keepHighest = droppableSubmissionData.length - dropLowest
  const keepLowest = keepHighest - dropHighest
  const hasPointed: boolean = droppableSubmissionData.some(submission => submission.total > 0)

  let submissionsToKeep: DroppableSubmission[]
  if (hasPointed) {
    submissionsToKeep = dropPointed(droppableSubmissionData, cannotDrop, keepHighest, keepLowest)
  } else {
    submissionsToKeep = dropUnpointed(droppableSubmissionData, keepHighest, keepLowest)
  }

  submissionsToKeep = [...submissionsToKeep, ...cannotDrop]

  droppableSubmissionData
    .filter(submission => !submissionsToKeep.includes(submission))
    .forEach(submission => {
      submission.drop = true
    })

  return submissionsToKeep
}

function calculateGroupGrade(
  group: AssignmentGroup,
  allSubmissions: SubmissionGradeCriteria[],
  opts: {
    ignoreUnpostedAnonymous: boolean
    includeUngraded: boolean
  }
): AggregateGrade {
  // Remove assignments without visibility from gradeableAssignments.
  const hiddenAssignmentsById = allSubmissions
    .filter(submission => submission.hidden)
    .reduce((result, submission) => {
      result[submission.assignment_id] = submission
      return result
    }, {})
  const ungradeableCriteria = (assignment: Assignment) =>
    assignment.omit_from_final_grade ||
    hiddenAssignmentsById[assignment.id] ||
    JSON.stringify(assignment.submission_types) === JSON.stringify(['not_graded']) ||
    assignment.workflow_state === 'unpublished' ||
    (opts.ignoreUnpostedAnonymous && assignment.anonymize_students)
  const gradeableAssignments =
    group?.assignments?.filter((assignment: Assignment) => !ungradeableCriteria(assignment)) || []
  const assignments = gradeableAssignments.reduce((result, item) => {
    result[item.id] = item
    return result
  }, {})

  // Remove submissions from other assignment groups.
  let submissions: SubmissionGradeCriteria = allSubmissions.filter(
    (submission: SubmissionGradeCriteria) => assignments[submission.assignment_id]
  )

  // Remove excused submissions.
  submissions = submissions.filter(submission => submission.excused !== true)

  const submissionData = submissions.map((submission: SubmissionGradeCriteria) => ({
    total: parseScore(assignments[submission.assignment_id].points_possible),
    score: parseScore(submission.score),
    // @ts-expect-error
    submitted: submission.score != null && submission.score !== '',
    pending_review: submission.workflow_state === 'pending_review',
    submission,
  }))

  let relevantSubmissionData = submissionData
  if (!opts.includeUngraded) {
    relevantSubmissionData = submissionData.filter(
      submission => submission.submitted && !submission.pending_review
    )
  }

  const submissionsToKeep = dropAssignments(relevantSubmissionData, group.rules)
  const score = sum(submissionsToKeep.map(submission => parseScore(submission.score)))
  const possible = sumBy(submissionsToKeep, 'total')

  return {
    score,
    possible,
    submission_count: submissionData.filter(submission => submission.submitted).length,
    submissions: submissionData.map(submissionDatum => {
      const percent = submissionDatum.total
        ? divide(submissionDatum.score, submissionDatum.total)
        : 0
      return {
        drop: submissionDatum.drop,
        percent: parseScore(percent),
        score: parseScore(submissionDatum.score),
        possible: submissionDatum.total,
        submission: submissionDatum.submission,
        submitted: submissionDatum.submitted,
      }
    }),
  }
}

// Each submission requires the following properties:
// * score: number
// * points_possible: non-negative integer
// * assignment_id: <Canvas id>
// * assignment_group_id: <Canvas id>
// * excused: boolean
//
// Ungraded submissions will have a score of `null`.
//
// An assignment group requires the following properties:
// * id: Canvas id
// * rules: object *see below
// * group_weight: non-negative number
// * assignments: array *see below
//
// `rules` has the following properties:
// * drop_lowest: non-negative integer
// * drop_highest: non-negative integer
// * never_drop: [array of assignment ids]
//
// `assignments` is an array of objects with the following properties:
// * id: <Canvas id>
// * points_possible: non-negative number
// * submission_types: [array of strings]
// * anonymize_students: boolean
//
// An AssignmentGroup Grade has the following shape:
// {
//   score: number|null
//   possible: number|null
//   submission_count: non-negative number
//   submissions: [array of Submissions]
// }
//
// Return value is an AssignmentGroup Grade Set.
// An AssignmentGroup Grade Set has the following shape:
// {
//   assignmentGroupId: <Canvas id>
//   assignmentGroupWeight: number
//   current: <AssignmentGroup Grade *see above>
//   final: <AssignmentGroup Grade *see above>
//   scoreUnit: 'points'
// }
function calculate(
  allSubmissions: SubmissionGradeCriteria[],
  assignmentGroup: AssignmentGroup,
  ignoreUnpostedAnonymous: boolean
): AssignmentGroupGrade {
  const uniqAssignmentIds = new Set()
  const submissions = allSubmissions.filter(sub => {
    if (!uniqAssignmentIds.has(sub.assignment_id)) {
      uniqAssignmentIds.add(sub.assignment_id)
      return true
    }
    return false
  })

  return {
    assignmentGroupId: assignmentGroup.id,
    assignmentGroupWeight: assignmentGroup.group_weight,
    current: calculateGroupGrade(assignmentGroup, submissions, {
      includeUngraded: false,
      ignoreUnpostedAnonymous,
    }),
    final: calculateGroupGrade(assignmentGroup, submissions, {
      includeUngraded: true,
      ignoreUnpostedAnonymous,
    }),
    scoreUnit: 'points',
  }
}

export default {
  calculate,
  dropAssignments,
}
