/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import mockGraphqlQuery from '@canvas/graphql-query-mock'
import {
  DELETE_COMMENT_MUTATION,
  CREATE_COMMENT_MUTATION,
  UPDATE_COMMENT_MUTATION,
} from '../graphql/Mutations'
import {COMMENTS_QUERY} from '../graphql/Queries'

const generateComments = (start, end) => {
  const comments = []
  for (let i = start; i < end; i++) {
    comments.push({
      __typename: 'CommentBankItem',
      _id: i.toString(),
      comment: `Comment item ${i}`,
    })
  }
  return comments
}

const generateCommentBankItems = (nodes, hasNextPage, endCursor) => ({
  data: {
    legacyNode: {
      _id: '1',
      __typename: 'User',
      commentBankItemsConnection: {
        __typename: 'CommentBankItemsConnection',
        nodes,
        pageInfo: {__typename: 'PageInfo', hasNextPage, endCursor},
      },
    },
  },
})

export const commentBankItemMocksV2 = () => {
  return [
    {
      delay: 200,
      request: {query: COMMENTS_QUERY, variables: {userId: '1'}},
      result: generateCommentBankItems(generateComments(0, 10), true, 'cursor-10'),
    },
    {
      delay: 200,
      request: {query: COMMENTS_QUERY, variables: {userId: '1', after: 'cursor-10'}},
      result: generateCommentBankItems(generateComments(10, 15), false, null),
    },
    {
      delay: 200,
      request: {query: COMMENTS_QUERY, variables: {userId: '1', query: 'search', maxResults: 5}},
      result: generateCommentBankItems(generateComments(0, 3), false, null),
    },
  ]
}

export const commentBankItemMocks = ({userId = '1', numberOfComments = 10} = {}) => [
  {
    request: {
      query: COMMENTS_QUERY,
      variables: {
        userId,
      },
    },
    result: {
      data: {
        legacyNode: {
          _id: '1',
          __typename: 'User',
          commentBankItemsConnection: {
            __typename: 'CommentBankItemsConnection',
            nodes: new Array(numberOfComments).fill(0).map((_v, i) => ({
              __typename: 'CommentBankItem',
              _id: i.toString(),
              comment: `Comment item ${i}`,
            })),
            pageInfo: {
              __typename: 'PageInfo',
              hasNextPage: false,
              endCursor: 'abcdef',
            },
          },
        },
      },
    },
  },
]

export async function makeCreateMutationMock({overrides = {}, variables = {}} = {}) {
  const result = await mockGraphqlQuery(CREATE_COMMENT_MUTATION, overrides, variables)

  return [
    {
      request: {
        query: CREATE_COMMENT_MUTATION,
        variables,
      },
      result,
    },
  ]
}

export async function makeDeleteCommentMutation({overrides = {}, variables = {}} = {}) {
  const result = await mockGraphqlQuery(DELETE_COMMENT_MUTATION, overrides, variables)

  return [
    {
      request: {
        query: DELETE_COMMENT_MUTATION,
        variables,
      },
      result,
    },
  ]
}

export const searchMocks = ({userId = '1', query = 'search', first = 5} = {}) => [
  {
    request: {
      query: COMMENTS_QUERY,
      variables: {
        userId,
        query,
        first,
      },
    },
    result: {
      data: {
        legacyNode: {
          _id: '1',
          __typename: 'User',
          commentBankItemsConnection: {
            __typename: 'CommentBankItemsConnection',
            nodes: new Array(first).fill(0).map((_v, i) => ({
              __typename: 'CommentBankItem',
              _id: i.toString(),
              comment: `search result ${i}`,
            })),
            pageInfo: {
              __typename: 'PageInfo',
              hasNextPage: false,
              endCursor: 'abcdef',
            },
          },
        },
      },
    },
  },
]

export async function makeUpdateMutationMock({overrides = {}, variables = {}} = {}) {
  const result = await mockGraphqlQuery(UPDATE_COMMENT_MUTATION, overrides, variables)

  return [
    {
      request: {
        query: UPDATE_COMMENT_MUTATION,
        variables,
      },
      result,
    },
  ]
}
