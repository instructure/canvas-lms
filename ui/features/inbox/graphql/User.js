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
import gql from 'graphql-tag'
import {shape, string} from 'prop-types'

export const User = {
  fragment: gql`
    fragment User on User {
      _id
      avatarUrl
      pronouns
      name
    }
  `,

  shape: shape({
    _id: string,
    avatarUrl: string,
    pronouns: string,
    name: string
  }),

  mock: ({
    avatarUrl = 'data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==',
    name = 'Hank Mccoy',
    pronouns = null,
    _id = '9'
  } = {}) => ({
    avatarUrl,
    name,
    pronouns,
    __typename: 'User',
    _id
  })
}

export const DefaultMocks = {
  User: () => ({
    name: 'Scott Summers',
    pronouns: 'He/Him'
  })
}
