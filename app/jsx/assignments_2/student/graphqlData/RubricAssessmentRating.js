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
import gql from 'graphql-tag'
import {number, shape, string} from 'prop-types'

export const RubricAssessmentRating = {
  fragment: gql`
    fragment RubricAssessmentRating on RubricAssessmentRating {
      _id
      criterion {
        id: _id
      }
      comments
      comments_html: commentsHtml
      description
      outcome {
        id: _id
      }
      points
    }
  `,

  shape: shape({
    _id: string,
    criterion: shape({
      id: string.isRequired
    }),
    comments: string,
    comments_html: string,
    description: string,
    outcome: shape({
      id: string.isRequired
    }),
    points: number
  })
}

export const RubricAssessmentRatingDefaultMocks = {
  RubricAssessmentRating: () => ({
    _id: '1',
    outcome: null,
    points: 6
  })
}
