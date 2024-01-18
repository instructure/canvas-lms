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

import gql from 'graphql-tag'
import {executeQuery} from '@canvas/query/graphql'

const RUBRIC_QUERY = gql`
  query RubricQuery($id: ID!) {
    rubric(id: $id) {
      id: _id
      title
      criteria {
        points
        description
        longDescription
        ignoreForScoring
        masteryPoints
        criterionUseRange
      }
      criteriaCount
      freeFormCriterionComments
      hideScoreTotal
      pointsPossible
      workflowState
    }
  }
`

type RubricQueryResponse = {
  rubric: {
    id: string
    title: string
    criteria: {
      points: number
      description: string
      longDescription: string
      ignoreForScoring: boolean
      masteryPoints: number
      criterionUseRange: boolean
    }
    criteriaCount: number
    freeFormCriterionComments: boolean
    hideScoreTotal: boolean
    pointsPossible: number
    workflowState: string
  }
}

export const fetchRubric = async (id?: string) => {
  if (!id) return null

  const {rubric} = await executeQuery<RubricQueryResponse>(RUBRIC_QUERY, {
    id,
  })
  return rubric
}
