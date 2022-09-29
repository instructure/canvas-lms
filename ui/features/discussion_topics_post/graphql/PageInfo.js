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

import {bool, shape, string} from 'prop-types'
import gql from 'graphql-tag'

export const PageInfo = {
  fragment: gql`
    fragment PageInfo on PageInfo {
      endCursor
      hasNextPage
      hasPreviousPage
      startCursor
    }
  `,

  shape: shape({
    endCursor: string,
    hasNextPage: bool,
    hasPreviousPage: bool,
    startCursor: string,
  }),

  mock: ({
    endCursor = 'MjA',
    hasNextPage = true,
    hasPreviousPage = true,
    startCursor = 'MQ',
  } = {}) => ({
    endCursor,
    hasNextPage,
    hasPreviousPage,
    startCursor,
    __typename: 'PageInfo',
  }),
}
