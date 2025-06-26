/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

function transformRubricCriterionRatingData(rating) {
  const {_id, ...ratingCopy} = {...rating, id: rating._id}
  return ratingCopy
}

function transformRubricCriterionData(criterion) {
  const {_id, outcome, ...criterionCopy} = {
    ...criterion,
    id: criterion._id,
    learning_outcome_id: criterion.outcome?._id,
  }

  if (criterionCopy.ratings) {
    criterionCopy.ratings = criterionCopy.ratings.map(rating =>
      transformRubricCriterionRatingData(rating),
    )
  }

  return criterionCopy
}

function transformRubricRatingData(rating) {
  // The Rubric component looks for the "id" field instead of "_id" (which
  // the query returns) to determine the selected rating, so add it in.
  // We don't want to change the component since it's also used by other
  // non-GraphQL pages.
  const {criterion, outcome, ...ratingCopy} = {
    ...rating,
    id: rating._id,
    criterion_id: rating.criterion?._id || null,
    learning_outcome_id: rating.outcome?._id || null,
  }

  return ratingCopy
}

export function transformRubricData(rubric) {
  if (!rubric) {
    return rubric
  }

  const {_id, ...rubricCopy} = {...rubric, id: rubric._id}
  if (rubricCopy.criteria) {
    rubricCopy.criteria = rubricCopy.criteria.map(criterion =>
      transformRubricCriterionData(criterion),
    )
  }

  return rubricCopy
}

export function transformRubricAssessmentData(rubricAssessment) {
  if (!rubricAssessment) {
    return rubricAssessment
  }

  const assessmentCopy = {...rubricAssessment}
  if (assessmentCopy.data) {
    assessmentCopy.data = assessmentCopy.data.map(rating => transformRubricRatingData(rating))
  }

  return assessmentCopy
}

export function shouldRenderSelfAssessment({assignment, submission, allowChangesToSubmission}) {
  if (!assignment || !submission || !allowChangesToSubmission) {
    return false
  }

  return (
    !assignment.env.peerReviewModeEnabled &&
    ENV.enhanced_rubrics_enabled &&
    assignment.rubric &&
    assignment.rubricSelfAssessmentEnabled &&
    allowChangesToSubmission &&
    !assignment.lockInfo.isLocked &&
    submission.gradingStatus !== 'excused'
  )
}

export function isRubricComplete(assessment) {
  return (
    assessment?.data.every(criterion => {
      const points = criterion.points
      const hasPoints = points?.value !== undefined
      const hasComments = !!criterion.comments?.length
      return (hasPoints || hasComments) && points?.valid
    }) || false
  )
}

export const parseCriterion = (data, rubric) => {
  const key = `criterion_${data.criterion_id}`
  const criterion = rubric.criteria.find(criterion => criterion.id === data.criterion_id)
  const rating = criterion.ratings.find(
    criterionRatings => criterionRatings.points === data.points?.value,
  )

  return {
    [key]: {
      rating_id: rating?.id,
      points: data.points?.value,
      description: data.description,
      comments: data.comments,
      save_comment: 1,
    },
  }
}
