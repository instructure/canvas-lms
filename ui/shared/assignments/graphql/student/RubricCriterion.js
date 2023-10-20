/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {arrayOf, bool, number, shape, string} from 'prop-types'
import gql from 'graphql-tag'
import {RubricRating} from './RubricRating'

export const RubricCriterion = {
  fragment: gql`
    fragment RubricCriterion on RubricCriterion {
      _id
      criterion_use_range: criterionUseRange
      description
      ignore_for_scoring: ignoreForScoring
      long_description: longDescription
      mastery_points: masteryPoints
      outcome {
        _id
      }
      points
      ratings {
        ...RubricRating
      }
    }
    ${RubricRating.fragment}
  `,

  shape: shape({
    id: string.isRequired,
    criterion_use_range: bool.isRequired,
    description: string.isRequired,
    ignore_for_scoring: bool,
    learning_outcome_id: string,
    long_description: string,
    mastery_points: number,
    points: number,
    ratings: arrayOf(RubricRating.shape),
  }),

  mock: ({
    _id = '1',
    criterion_use_range = false,
    description = 'Criterion Description',
    ignore_for_scoring = false,
    learning_outcome_id = '1',
    long_description = 'Criterion Long Description',
    mastery_points = null,
    outcome = null,
    points = 6,
    ratings = [RubricRating.mock()],
  } = {}) => ({
    _id,
    criterion_use_range,
    description,
    ignore_for_scoring,
    learning_outcome_id,
    long_description,
    mastery_points,
    outcome,
    points,
    ratings,
  }),
}

export const DefaultMocks = {
  RubricCriterion: () => ({
    _id: '1',
    criterionUseRange: false,
    ignoreForScoring: false,
    masteryPoints: null,
    outcome: null,
    points: 6,
    ratings: [{}],
  }),
}
