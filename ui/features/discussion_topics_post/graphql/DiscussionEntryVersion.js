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

import gql from 'graphql-tag'
import {shape, string, number} from 'prop-types'

export const DiscussionEntryVersion = {
  fragment: gql`
    fragment DiscussionEntryVersion on DiscussionEntryVersion {
      _id
      id
      version
      message
      updatedAt
      createdAt
    }
  `,

  shape: shape({
    _id: string,
    id: string,
    version: number,
    message: string,
    updatedAt: string,
    createdAt: string,
  }),

  mock: ({
    _id = 'RGlzY3Vzc2lvbkVudHJ5VmVyc2lvbi0x',
    id = '1',
    version = 1,
    message = 'This is the original message!',
    createdAt = '2022-10-31T10:15:55-04:00',
    updatedAt = '2022-10-31T10:15:55-04:00',
  } = {}) => ({
    id,
    _id,
    version,
    message,
    createdAt,
    updatedAt,
    __typename: 'DiscussionEntryVersion',
  }),
}
