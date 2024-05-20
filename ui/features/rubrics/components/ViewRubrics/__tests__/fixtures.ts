/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import type {Rubric} from '@canvas/rubrics/react/types/rubric'
import type {RubricQueryResponse} from 'features/rubrics/types/Rubric'

export const RUBRICS_DATA: Rubric[] = [
  {
    id: '1',
    title: 'Rubric 1',
    criteriaCount: 1,
    criteria: [
      {
        id: '1',
        points: 5,
        description: 'Criterion 1',
        longDescription: 'Long description for criterion 1',
        ignoreForScoring: false,
        masteryPoints: 3,
        criterionUseRange: false,
        ratings: [
          {
            id: '1',
            description: 'Rating 1',
            longDescription: 'Long description for rating 1',
            points: 5,
          },
          {
            id: '2',
            description: 'Rating 2',
            longDescription: 'Long description for rating 2',
            points: 0,
          },
        ],
      },
    ],
    hidePoints: false,
    hasRubricAssociations: false,
    pointsPossible: 5,
    ratingOrder: 'ascending',
    buttonDisplay: 'points',
    locations: [],
    workflowState: 'active',
  },
  {
    id: '2',
    title: 'Rubric 2',
    criteriaCount: 2,
    criteria: [
      {
        id: '1',
        points: 5,
        description: 'Criterion 1',
        longDescription: 'Long description for criterion 1',
        ignoreForScoring: false,
        masteryPoints: 3,
        criterionUseRange: false,
        ratings: [
          {
            id: '1',
            description: 'Rating 1',
            longDescription: 'Long description for rating 1',
            points: 5,
          },
          {
            id: '2',
            description: 'Rating 2',
            longDescription: 'Long description for rating 2',
            points: 0,
          },
        ],
      },
      {
        id: '2',
        points: 5,
        description: 'Criterion 2',
        longDescription: 'Long description for criterion 2',
        ignoreForScoring: false,
        masteryPoints: 3,
        criterionUseRange: false,
        ratings: [
          {
            id: '1',
            description: 'Rating 1',
            longDescription: 'Long description for rating 1',
            points: 5,
          },
          {
            id: '2',
            description: 'Rating 2',
            longDescription: 'Long description for rating 2',
            points: 0,
          },
        ],
      },
    ],
    hidePoints: false,
    hasRubricAssociations: false,
    pointsPossible: 10,
    ratingOrder: 'ascending',
    buttonDisplay: 'points',
    locations: [],
    workflowState: 'archived',
  },
  {
    id: '3',
    title: 'Rubric 3',
    criteriaCount: 3,
    criteria: [
      {
        id: '1',
        points: 5,
        description: 'Criterion 1',
        longDescription: 'Long description for criterion 1',
        ignoreForScoring: false,
        masteryPoints: 3,
        criterionUseRange: false,
        ratings: [
          {
            id: '1',
            description: 'Rating 1',
            longDescription: 'Long description for rating 1',
            points: 5,
          },
          {
            id: '2',
            description: 'Rating 2',
            longDescription: 'Long description for rating 2',
            points: 0,
          },
        ],
      },
      {
        id: '2',
        points: 5,
        description: 'Criterion 2',
        longDescription: 'Long description for criterion 2',
        ignoreForScoring: false,
        masteryPoints: 3,
        criterionUseRange: false,
        ratings: [
          {
            id: '1',
            description: 'Rating 1',
            longDescription: 'Long description for rating 1',
            points: 5,
          },
          {
            id: '2',
            description: 'Rating 2',
            longDescription: 'Long description for rating 2',
            points: 0,
          },
        ],
      },
      {
        id: '3',
        points: 5,
        description: 'Criterion 3',
        longDescription: 'Long description for criterion 3',
        ignoreForScoring: false,
        masteryPoints: 3,
        criterionUseRange: false,
        ratings: [
          {
            id: '1',
            description: 'Rating 1',
            longDescription: 'Long description for rating 1',
            points: 5,
          },
          {
            id: '2',
            description: 'Rating 2',
            longDescription: 'Long description for rating 2',
            points: 0,
          },
        ],
      },
    ],
    hidePoints: false,
    hasRubricAssociations: true,
    pointsPossible: 15,
    ratingOrder: 'ascending',
    buttonDisplay: 'points',
    locations: [],
    workflowState: 'active',
  },
]

export const RUBRICS_QUERY_RESPONSE: RubricQueryResponse = {
  rubricsConnection: {
    nodes: RUBRICS_DATA,
  },
}

export const RUBRIC_PREVIEW_QUERY_RESPONSE: Pick<Rubric, 'criteria' | 'title' | 'ratingOrder'> = {
  criteria: RUBRICS_DATA[0].criteria,
  title: RUBRICS_DATA[0].title,
  ratingOrder: RUBRICS_DATA[0].ratingOrder,
}
