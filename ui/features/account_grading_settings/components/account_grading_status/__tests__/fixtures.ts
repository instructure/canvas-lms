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

import type {MockedResponse} from '@apollo/react-testing'
import {
  DELETE_CUSTOM_GRADING_STATUS_MUTATION,
  UPSERT_CUSTOM_GRADING_STATUS_MUTATION,
  UPSERT_STANDARD_GRADING_STATUS_MUTATION,
} from '../../../graphql/mutations/GradingStatusMutations'
import {ACCOUNT_GRADING_STATUS_QUERY} from '../../../graphql/queries/GradingStatusQueries'
import type {
  CustomGradingStatusUpsertResponse,
  StandardGradingStatusUpsertResponse,
} from '../../../types/accountStatusMutations'

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

const UPSERT_STANDARD_GRADING_STATUS_MUTATION_RESPONSE: StandardGradingStatusUpsertResponse = {
  upsertStandardGradeStatus: {
    standardGradeStatus: {
      id: '1',
      color: '#F0E8EF',
      name: 'missing',
    },
    errors: [],
  },
}

const UPSERT_CUSTOM_GRADING_STATUS_MUTATION_RESPONSE: CustomGradingStatusUpsertResponse = {
  upsertCustomGradeStatus: {
    customGradeStatus: {
      color: '#E5F3FC',
      name: 'New Status 10',
      id: '1',
    },
    errors: [],
  },
}

const NEW_CUSTOM_STATUS_MUTATION_RESPONSE: CustomGradingStatusUpsertResponse = {
  upsertCustomGradeStatus: {
    customGradeStatus: {
      color: '#E5F3FC',
      name: 'New Status 11',
      id: '11',
    },
    errors: [],
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
    {
      request: {
        query: UPSERT_STANDARD_GRADING_STATUS_MUTATION,
        variables: {
          color: '#F0E8EF',
          name: 'missing',
          id: '1',
        },
      },
      result: {
        data: UPSERT_STANDARD_GRADING_STATUS_MUTATION_RESPONSE,
      },
    },
    {
      request: {
        query: DELETE_CUSTOM_GRADING_STATUS_MUTATION,
        variables: {
          id: '2',
        },
      },
      result: {
        data: {
          deleteCustomGradeStatus: {
            customGradeStatusId: '2',
            errors: [],
          },
        },
      },
    },
    {
      request: {
        query: UPSERT_CUSTOM_GRADING_STATUS_MUTATION,
        variables: {
          color: '#E5F3FC',
          name: 'New Status 10',
          id: '1',
        },
      },
      result: {
        data: UPSERT_CUSTOM_GRADING_STATUS_MUTATION_RESPONSE,
      },
    },
    {
      request: {
        query: UPSERT_CUSTOM_GRADING_STATUS_MUTATION,
        variables: {
          color: '#E5F3FC',
          name: 'New Status 11',
        },
      },
      result: {
        data: NEW_CUSTOM_STATUS_MUTATION_RESPONSE,
      },
    },
  ]
}
