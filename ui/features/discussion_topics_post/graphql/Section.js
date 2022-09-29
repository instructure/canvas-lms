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

import gql from 'graphql-tag'
import {number, shape, string} from 'prop-types'

export const Section = {
  fragment: gql`
    fragment Section on Section {
      _id
      createdAt
      id
      name
      updatedAt
      userCount
    }
  `,

  shape: shape({
    _id: string,
    createdAt: string,
    id: string,
    name: string,
    updatedAt: string,
    userCount: number,
  }),

  mock: ({
    _id = 'U2VjdGlvbi0y',
    createdAt = '2020-11-13T11:27:58-07:00',
    id = '2',
    name = 'X-Men A-Team',
    updatedAt = '2020-11-13T11:27:58-07:00',
    userCount = 1,
  } = {}) => ({
    _id,
    createdAt,
    id,
    name,
    updatedAt,
    userCount,
    __typename: 'Section',
  }),
}
