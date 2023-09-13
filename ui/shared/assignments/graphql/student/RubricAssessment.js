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

import {arrayOf, number, shape, string} from 'prop-types'
import gql from 'graphql-tag'
import {RubricAssessmentRating} from './RubricAssessmentRating'
import {RubricAssociation} from './RubricAssociation'

export const RubricAssessment = {
  fragment: gql`
    fragment RubricAssessment on RubricAssessment {
      _id
      artifactAttempt
      assessment_type: assessmentType
      assessor {
        _id
        name
        shortName
        enrollments(courseId: $courseID) {
          type
        }
      }
      data: assessmentRatings {
        ...RubricAssessmentRating
      }
      rubric_association: rubricAssociation {
        ...RubricAssociation
      }
      score
    }
    ${RubricAssessmentRating.fragment}
    ${RubricAssociation.fragment}
  `,

  shape: shape({
    _id: string.isRequired,
    artifactAttempt: number,
    assessment_type: string,
    assessor: shape({
      _id: string.isRequired,
      name: string,
      shortName: string,
    }),
    data: arrayOf(RubricAssessmentRating.shape),
    rubricAssociation: RubricAssociation.shape,
    score: number,
  }),

  mock: ({
    _id = '1',
    artifactAttempt = 1,
    assessment_type = 'grading',
    assessor = {
      _id: '1',
      name: 'Assessor Name',
      shortName: 'Assessor Display Name',
    },
    data = [RubricAssessmentRating.mock()],
    rubric_association = RubricAssociation.mock(),
    score = 10,
  } = {}) => ({
    _id,
    artifactAttempt,
    assessment_type,
    assessor,
    data,
    rubric_association,
    score,
  }),
}

export const DefaultMocks = {
  RubricAssessment: () => ({
    _id: '1',
    artifactAttempt: '1',
    assessmentType: 'grading',
    assessmentRatings: [{}],
    score: '10',
  }),
}
