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
import {arrayOf, shape, string} from 'prop-types'

export const User = {
  fragment: gql`
    fragment User on User {
      id
      _id
      avatarUrl
      displayName: shortName
      htmlUrl
      courseRoles
      pronouns
    }
  `,

  shape: shape({
    id: string,
    _id: string,
    avatarUrl: string,
    displayName: string,
    htmlUrl: string,
    courseRoles: arrayOf(string),
    pronouns: string,
  }),

  mock: ({
    id = 'VXNlci0y',
    _id = '2',
    avatarUrl = 'data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==',
    displayName = 'Hank Mccoy',
    htmlUrl = '',
    courseRoles = [],
    pronouns = null,
  } = {}) => ({
    id,
    _id,
    avatarUrl,
    displayName,
    htmlUrl,
    courseRoles,
    pronouns,
    __typename: 'User',
  }),
}

export const DefaultMocks = {
  User: () => ({
    _id: '1',
    avatarUrl: 'someFakeUrl',
    displayName: 'Turd Ferguson',
    htmlUrl: '',
    courseRoles: [],
    pronouns: null,
  }),
}
