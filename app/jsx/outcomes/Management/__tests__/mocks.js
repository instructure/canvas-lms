/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {GET_OUTCOME_GROUPS_QUERY} from '../api'

export const accountMocks = ({childGroupsCount = 1} = {}) => [
  {
    request: {
      query: GET_OUTCOME_GROUPS_QUERY('account'),
      variables: {
        contextId: '1'
      }
    },
    result: {
      data: {
        context: {
          rootOutcomeGroup: {
            childGroupsCount,
            __typename: 'LearningOutcomeGroup'
          },
          __typename: 'Account'
        }
      }
    }
  }
]

export const courseMocks = ({childGroupsCount = 1} = {}) => [
  {
    request: {
      query: GET_OUTCOME_GROUPS_QUERY('course'),
      variables: {
        contextId: '2'
      }
    },
    result: {
      data: {
        context: {
          rootOutcomeGroup: {
            childGroupsCount,
            __typename: 'LearningOutcomeGroup'
          },
          __typename: 'Course'
        }
      }
    }
  }
]
