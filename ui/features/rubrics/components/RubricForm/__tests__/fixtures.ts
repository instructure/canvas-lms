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

import type {Rubric} from '@canvas/rubrics/react/types/rubric'

export const RUBRICS_QUERY_RESPONSE: Rubric = {
  id: '1',
  title: 'Rubric 1',
  criteriaCount: 2,
  locations: [],
  pointsPossible: 10,
  workflowState: 'active',
  buttonDisplay: 'numeric',
  ratingOrder: 'ascending',
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
}
