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
import {shape, string} from 'prop-types'

export const ChildTopic = {
  fragment: gql`
    fragment ChildTopic on ChildTopic {
      id
      _id
      contextName
      contextId
    }
  `,

  shape: shape({
    id: string,
    _id: string,
    contextName: string,
    contextId: string
  }),

  mock: ({
    id = 'QXNzaWdubWVudC0x22',
    _id = '1',
    contextName = 'RGlzY3Vzc2lvbi0xMA==',
    contextId = '5'
  } = {}) => ({
    id,
    _id,
    contextId,
    contextName,
    __typename: 'ChildTopic'
  })
}
