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
import {RubricCriterion} from './RubricCriterion'

export const Rubric = {
  fragment: gql`
    fragment Rubric on Rubric {
      criteria {
        ...RubricCriterion
      }
      _id
      free_form_criterion_comments: freeFormCriterionComments
      hide_score_total: hideScoreTotal
      points_possible: pointsPossible
      title
    }
    ${RubricCriterion.fragment}
  `,

  shape: shape({
    id: string.isRequired,
    criteria: arrayOf(RubricCriterion.shape),
    free_form_criterion_comments: bool,
    hide_score_total: bool,
    points_possible: number.isRequired,
    title: string.isRequired,
  }),

  mock: ({
    _id = '1',
    criteria = [RubricCriterion.mock()],
    free_form_criterion_comments = false,
    hide_score_total = false,
    points_possible = 10,
    title = 'Rubric Title',
  } = {}) => ({
    _id,
    criteria,
    free_form_criterion_comments,
    hide_score_total,
    points_possible,
    title,
  }),
}

export const DefaultMocks = {
  Rubric: () => ({
    _id: '1',
    criteria: [{}],
    freeFormCriterionComments: false,
  }),
}
