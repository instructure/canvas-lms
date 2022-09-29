/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import PropTypes from 'prop-types'

export const pointShape = {
  text: PropTypes.string,
  value: PropTypes.number,
  valid: PropTypes.bool,
}

export const tierShape = {
  points: PropTypes.number,
  description: PropTypes.string,
  long_description: PropTypes.string,
  endOfRangePoints: PropTypes.number,
}

export const ratingShape = {
  tiers: PropTypes.arrayOf(PropTypes.shape(tierShape)).isRequired,
  points: PropTypes.number,
  selectedRatingId: PropTypes.string,
  defaultMasteryThreshold: PropTypes.number,
  useRange: PropTypes.bool.isRequired,
}

export const assessmentShape = {
  criterion_id: PropTypes.string.isRequired,
  comments: PropTypes.string,
  points: PropTypes.shape(pointShape).isRequired,
  focusPoints: PropTypes.number,
  saveCommentsForLater: PropTypes.bool,
}

export const criterionShape = {
  id: PropTypes.string.isRequired,
  description: PropTypes.string,
  long_description: PropTypes.string,
  learning_outcome_id: PropTypes.string,
  points: PropTypes.number,
  ratings: PropTypes.arrayOf(PropTypes.shape(tierShape)),
  mastery_points: PropTypes.number,
}

export const rubricShape = {
  criteria: PropTypes.arrayOf(PropTypes.shape(criterionShape)),
  free_form_criterion_comments: PropTypes.bool,
  points_possible: PropTypes.number.isRequired,
  title: PropTypes.string.isRequired,
}

export const rubricAssociationShape = {
  hide_score_total: PropTypes.bool,
  summary_data: PropTypes.shape({
    saved_comments: PropTypes.objectOf(PropTypes.arrayOf(PropTypes.string)),
  }),
}

export const rubricAssessmentShape = {
  data: PropTypes.arrayOf(PropTypes.shape(assessmentShape)).isRequired,
  score: PropTypes.number,
}
