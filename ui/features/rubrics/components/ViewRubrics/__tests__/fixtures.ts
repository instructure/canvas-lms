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
    criteriaCount: 5,
    locations: [],
    pointsPossible: 10,
    workflowState: 'active',
  },
  {
    id: '2',
    title: 'Rubric 2',
    criteriaCount: 3,
    locations: [],
    pointsPossible: 30,
    workflowState: 'archived',
  },
  {
    id: '3',
    title: 'Rubric 3',
    criteriaCount: 5,
    locations: [],
    pointsPossible: 20,
    workflowState: 'active',
  },
]

export const RUBRICS_QUERY_RESPONSE: RubricQueryResponse = {
  rubricsConnection: {
    nodes: RUBRICS_DATA,
  },
}
