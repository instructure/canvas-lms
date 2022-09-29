/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {arrayOf, shape, string} from 'prop-types'
import gql from 'graphql-tag'

export const Course = {
  fragment: gql`
    fragment Course on Course {
      _id
      id
      name
      usersConnection {
        nodes {
          _id
          id
          name
        }
      }
    }
  `,
  shape: shape({
    _id: string,
    id: string,
    name: string,
    usersConnection: shape({
      nodes: arrayOf({
        _id: string,
        id: string,
        name: string,
      }),
    }),
  }),
  mock: {
    _id: 'asdfasdfasdf',
    id: '144',
    name: 'Course 1',
    usersConnection: shape({
      nodes: [
        {
          _id: 'iuejvUDIUShgdi832',
          id: '234',
          name: 'Ron Weasley',
        },
      ],
    }),
  },
}
