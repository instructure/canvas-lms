/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {executeQuery} from '@canvas/graphql'
import {gql} from 'graphql-tag'
import type {GetRubricOutcomeQuery} from '@canvas/graphql/codegen/graphql'

const GET_RUBRIC_OUTCOME = gql`
  query GetRubricOutcome($learningOutcomeId: ID!) {
    learningOutcome(id: $learningOutcomeId) {
      id: _id
      calculationInt
      calculationMethod
      contextId
      contextType
      displayName
      description
      masteryPoints
      title
    }
  }
`

type QueryFunctionProps = {
  queryKey: string[]
}
export const getRubricOutcome = async ({
  queryKey,
}: QueryFunctionProps): Promise<GetRubricOutcomeQuery['learningOutcome'] | undefined | null> => {
  const learningOutcomeId = queryKey[1]

  if (!learningOutcomeId) {
    return
  }

  const result = await executeQuery<GetRubricOutcomeQuery>(GET_RUBRIC_OUTCOME, {
    learningOutcomeId,
  })

  return result.learningOutcome
}
