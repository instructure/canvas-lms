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
        _id
      }
      comments
      comments_html: commentsHtml
      description
      outcome {
        _id
      }
      points
      artifactAttempt
    }
  `,

  shape: shape({
    id: string,
    comments: string,
    comments_html: string,
    criterion_id: string,
    description: string,
    learning_outcome_id: string,
    points: number,
    artifactAttempt: number
  })
}

export const DefaultMocks = {
  RubricAssessmentRating: () => ({
    _id: '1',
    outcome: null,
    points: 6,
    artifactAttempt: '1'
  })
}
