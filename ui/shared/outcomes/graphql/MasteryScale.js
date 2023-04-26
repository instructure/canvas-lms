/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import axios from '@canvas/axios'
import pluralize from '@canvas/util/stringPluralize'
import {gql} from '@canvas/apollo'

export const ACCOUNT_OUTCOME_PROFICIENCY_QUERY = gql`
  query GetOutcomeProficiencyData($contextId: ID!) {
    context: account(id: $contextId) {
      outcomeProficiency {
        _id
        contextId
        contextType
        proficiencyRatingsConnection {
          nodes {
            _id
            color
            description
            mastery
            points
          }
        }
      }
    }
  }
`

export const COURSE_OUTCOME_PROFICIENCY_QUERY = gql`
  query GetOutcomeProficiencyData($contextId: ID!) {
    context: course(id: $contextId) {
      outcomeProficiency {
        _id
        contextId
        contextType
        proficiencyRatingsConnection {
          nodes {
            _id
            color
            description
            mastery
            points
          }
        }
      }
    }
  }
`

export const saveProficiency = (contextType, contextId, config) => {
  return axios.post(
    `/api/v1/${pluralize(contextType).toLowerCase()}/${contextId}/outcome_proficiency`,
    config
  )
}
