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

import PropTypes from 'prop-types'

export const proficiencyRatingShape = {
  points: PropTypes.number,
  color: PropTypes.string,
  description: PropTypes.string.isRequired,
  masteryAt: PropTypes.number.isRequired,
}

export const studentShape = {
  id: PropTypes.string.isRequired,
  name: PropTypes.string.isRequired,
  display_name: PropTypes.string.isRequired,
  avatar_url: PropTypes.string,
}

export const outcomeRatingShape = {
  points: PropTypes.number.isRequired,
  color: PropTypes.string.isRequired,
  description: PropTypes.string.isRequired,
  mastery: PropTypes.bool.isRequired,
}

export const outcomeShape = {
  id: PropTypes.string.isRequired,
  title: PropTypes.string.isRequired,
  description: PropTypes.string,
  display_name: PropTypes.string,
  friendly_description: PropTypes.string,
  calculation_method: PropTypes.string.isRequired,
  calculation_int: PropTypes.number,
  mastery_points: PropTypes.number.isRequired,
  ratings: PropTypes.arrayOf(PropTypes.shape(outcomeRatingShape)).isRequired,
}

export const outcomeRollupShape = {
  outcomeId: PropTypes.string.isRequired,
  rating: PropTypes.shape(outcomeRatingShape).isRequired,
}

export const studentRollupsShape = {
  studentId: PropTypes.string.isRequired,
  outcomeRollups: PropTypes.arrayOf(PropTypes.shape(outcomeRollupShape)).isRequired,
}
