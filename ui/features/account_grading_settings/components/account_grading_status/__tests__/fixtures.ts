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

import {MockedResponse} from '@apollo/react-testing'
import {ACCOUNT_GRADING_STATUS_QUERY} from '../../../graphql/queries/GradingStatusQueries'

const ACCOUNT_GRADING_STATUS_QUERY_RESPONSE = {
  data: {
    account: {
      customGradeStatusesConnection: {
        nodes: [
          {
            id: '1',
            color: '#F033FF',
            name: 'test custom',
          },
          {
            id: '2',
            color: '#EEEEEE',
            name: 'custom 2',
          },
        ],
      },
      standardGradeStatusesConnection: {
        nodes: [
          {
            id: '1',
            color: '#E40606',
            name: 'missing',
          },
        ],
      },
    },
  },
}

export const setupGraphqlMocks = (): MockedResponse[] => {
  return [
    {
      request: {
        query: ACCOUNT_GRADING_STATUS_QUERY,
        variables: {accountId: '2'},
      },
      result: ACCOUNT_GRADING_STATUS_QUERY_RESPONSE,
    },
  ]
}
