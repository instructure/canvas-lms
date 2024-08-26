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

import type {Rubric, RubricAssociation} from '../../types/rubric'

export const RUBRIC: Rubric = {
  id: '1',
  criteriaCount: 1,
  pointsPossible: 10,
  title: 'Rubric 1',
  criteria: [
    {
      id: '1',
      description: 'Criterion 1',
      points: 10,
      criterionUseRange: false,
      ratings: [
        {
          description: 'Rating 1',
          points: 10,
          id: '1',
          longDescription: 'Rating 1 Long Description',
        },
        {
          description: 'Rating 2',
          points: 10,
          id: '2',
          longDescription: 'Rating 2 Long Description',
        },
      ],
    },
  ],
}

export const RUBRIC_ASSOCIATION: RubricAssociation = {
  hidePoints: false,
  hideScoreTotal: false,
  id: '1',
  useForGrading: true,
}
