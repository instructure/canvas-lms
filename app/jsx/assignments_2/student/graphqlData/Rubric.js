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
import {Criterion} from './Criterion'
import gql from 'graphql-tag'

export const Rubric = {
  fragment: gql`
    fragment Rubric on Rubric {
      _id
      context_id: contextId
      criteria {
        ...Criterion
      }
      free_form_criterion_comments: freeFormCriterionComments
      points_possible: pointsPossible
      title
    }
    ${Criterion.fragment}
  `,

  shape: shape({
    _id: string.isRequired,
    context_id: string.isRequired,
    criteria: arrayOf(Criterion.shape),
    free_form_criterion_comments: bool,
    points_possible: number.isRequired,
    title: string.isRequired
  })
}

export const RubricDefaultMocks = {
  Rubric: () => ({
    _id: '1',
    contextId: '2',
    criteria: [{}],
    freeFormCriterionComments: false,
    pointsPossible: 10,
    title: 'Rubric Title'
  })
}
