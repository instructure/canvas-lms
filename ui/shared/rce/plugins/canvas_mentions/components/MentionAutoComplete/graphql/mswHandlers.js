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

import {graphql, HttpResponse} from 'msw'

export const MentionMockUsers = [
  {
    _id: 'Aa',
    id: 1,
    name: 'Jeffrey Johnson',
    __typename: 'MessageableUser',
  },
  {
    _id: 'Ab',
    id: 2,
    name: 'Matthew Lemon',
    __typename: 'MessageableUser',
  },
  {
    _id: 'Ac',
    id: 3,
    name: 'Rob Orton',
    __typename: 'MessageableUser',
  },
  {
    _id: 'Ad',
    id: 4,
    name: 'Davis Hyer',
    __typename: 'MessageableUser',
  },
  {
    _id: 'Ae',
    id: 5,
    name: 'Drake Harper',
    __typename: 'MessageableUser',
  },
  {
    _id: 'Af',
    id: 6,
    name: 'Omar Soto-Fortuño',
    __typename: 'MessageableUser',
  },
  {
    _id: 'Ag',
    id: 7,
    name: 'Chawn Neal',
    __typename: 'MessageableUser',
  },
  {
    _id: 'Ah',
    id: 8,
    name: 'Mauricio Ribeiro',
    __typename: 'MessageableUser',
  },
  {
    _id: 'Ai',
    id: 9,
    name: 'Caleb Guanzon',
    __typename: 'MessageableUser',
  },
  {
    _id: 'Aj',
    id: 10,
    name: 'Jason Gillett',
    __typename: 'MessageableUser',
  },
]

export const handlers = [
  graphql.query('GetMentionableUsers', () => {
    return HttpResponse.json({
      data: {
        legacyNode: {
          id: 'Vxb',
          mentionableUsersConnection: {
            nodes: MentionMockUsers,
            __typename: 'MessageableUserConnection',
          },
          __typename: 'Discussion',
        },
      },
    })
  }),
]
