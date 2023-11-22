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

import gql from 'graphql-tag'
import {shape, string} from 'prop-types'
import {UsageRights} from './UsageRights'

export const Attachment = {
  fragment: gql`
    fragment Attachment on File {
      id
      _id
      displayName
      url
      usageRights {
        ...UsageRights
      }
    }
    ${UsageRights.fragment}
  `,

  shape: shape({
    id: string,
    _id: string,
    displayName: string,
    url: string,
    usageRights: UsageRights.shape,
  }),

  mock: ({
    id = 'RGlzY3Vzc2lvbi0y',
    _id = '7',
    displayName = '288777.jpeg',
    url = 'some_url',
    usageRights = UsageRights.mock(),
  } = {}) => ({
    id,
    _id,
    displayName,
    url,
    usageRights,
    __typename: 'File',
  }),
}
