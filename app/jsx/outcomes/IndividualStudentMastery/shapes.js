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

export const assignmentShape = PropTypes.shape({
  id: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  name: PropTypes.string.isRequired,
  html_url: PropTypes.string.isRequired,
  submission_types: PropTypes.string.isRequired
})

export const outcomeResultShape = PropTypes.shape({
  assignment: assignmentShape.isRequired,
  id: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  score: PropTypes.number,
  percent: PropTypes.number,
  hidden: PropTypes.bool,
  hide_points: PropTypes.bool
})

export const ratingShape = PropTypes.shape({
  description: PropTypes.string.isRequired
})

export const outcomeShape = PropTypes.shape({
  id: PropTypes.number.isRequired,
  mastered: PropTypes.bool.isRequired,
  ratings: PropTypes.arrayOf(ratingShape).isRequired,
  results: PropTypes.arrayOf(outcomeResultShape).isRequired,
  title: PropTypes.string.isRequired,
  mastery_points: PropTypes.number.isRequired,
  points_possible: PropTypes.number.isRequired
})

export const outcomeLinkShape = PropTypes.shape({
  outcome: outcomeShape.isRequired
})

export const outcomeGroupShape = PropTypes.shape({
  id: PropTypes.number.isRequired,
  title: PropTypes.string.isRequired
})

export const outcomeProficiencyRatingShape = PropTypes.shape({
  description: PropTypes.string.isRequired,
  points: PropTypes.number.isRequired,
  mastery: PropTypes.bool.isRequired,
  color: PropTypes.string.isRequired
})

export const outcomeProficiencyShape = PropTypes.shape({
  ratings: PropTypes.arrayOf(outcomeProficiencyRatingShape)
})
