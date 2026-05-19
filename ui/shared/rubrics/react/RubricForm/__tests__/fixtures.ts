/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import type {RubricQueryResponse} from '../queries/RubricFormQueries'

export const RUBRICS_QUERY_RESPONSE: RubricQueryResponse = {
  __typename: 'Rubric',
  id: '1',
  title: 'Rubric 1',
  pointsPossible: 10,
  workflowState: 'active',
  buttonDisplay: 'numeric',
  ratingOrder: 'ascending',
  freeFormCriterionComments: false,
  hasRubricAssociations: false,
  unassessed: true,
  canUpdateRubric: true,
  rubricAssociationForContext: {
    __typename: 'RubricAssociation',
    associationId: '1',
    associationType: 'Assignment',
    hidePoints: false,
    hideScoreTotal: false,
    hideOutcomeResults: false,
    id: 'association-1',
    useForGrading: false,
  },
  criteria: [
    {
      __typename: 'RubricCriterion',
      id: '1',
      points: 5,
      description: 'Criterion 1',
      longDescription: 'Long description for criterion 1',
      ignoreForScoring: false,
      masteryPoints: 3,
      criterionUseRange: false,
      learningOutcomeId: null,
      outcome: null,
      ratings: [
        {
          __typename: 'RubricRating',
          id: '1',
          description: 'Rating 1',
          longDescription: 'Long description for rating 1',
          points: 5,
        },
        {
          __typename: 'RubricRating',
          id: '2',
          description: 'Rating 2',
          longDescription: 'Long description for rating 2',
          points: 0,
        },
      ],
    },
    {
      __typename: 'RubricCriterion',
      id: '2',
      points: 5,
      description: 'Outcome Criterion 2',
      longDescription: '',
      ignoreForScoring: false,
      masteryPoints: 3,
      criterionUseRange: false,
      outcome: {
        displayName: 'Sample Outcome Display Name',
        title: 'Sample Outcome Title',
      },
      learningOutcomeId: '12345',
      ratings: [
        {
          __typename: 'RubricRating',
          id: '1',
          description: 'Outcome Rating 1',
          longDescription: '',
          points: 5,
        },
        {
          __typename: 'RubricRating',
          id: '2',
          description: 'Outcome Rating 2',
          longDescription: '',
          points: 0,
        },
      ],
    },
  ],
}

export const RUBRIC_CRITERIA_IGNORED_FOR_SCORING: RubricQueryResponse = {
  __typename: 'Rubric',
  id: '1',
  title: 'Rubric 1',
  pointsPossible: 10,
  workflowState: 'active',
  buttonDisplay: 'numeric',
  ratingOrder: 'ascending',
  freeFormCriterionComments: false,
  hasRubricAssociations: false,
  unassessed: true,
  canUpdateRubric: true,
  rubricAssociationForContext: {
    __typename: 'RubricAssociation',
    associationId: '1',
    associationType: 'Assignment',
    hidePoints: false,
    hideScoreTotal: false,
    hideOutcomeResults: false,
    id: 'association-1',
    useForGrading: false,
  },
  criteria: [
    {
      __typename: 'RubricCriterion',
      id: '1',
      points: 5,
      description: 'Criterion 1',
      longDescription: 'Long description for criterion 1',
      ignoreForScoring: true,
      masteryPoints: 3,
      criterionUseRange: false,
      learningOutcomeId: null,
      outcome: null,
      ratings: [
        {
          __typename: 'RubricRating',
          id: '1',
          description: 'Rating 1',
          longDescription: 'Long description for rating 1',
          points: 5,
        },
        {
          __typename: 'RubricRating',
          id: '2',
          description: 'Rating 2',
          longDescription: 'Long description for rating 2',
          points: 0,
        },
      ],
    },
  ],
}
