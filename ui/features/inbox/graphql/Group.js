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
import {bool, shape, string} from 'prop-types'

export const Group = {
  fragment: gql`
    fragment Group on Group {
      _id
      contextName: name
      assetString
      canMessage
    }
  `,

  shape: shape({
    _id: string,
    contextName: string,
    assetString: string,
    canMessage: bool,
  }),

  mock: ({
    _id = '1',
    contextName = 'Study Group 1',
    assetString = 'group_1',
    canMessage = false,
  } = {}) => ({
    _id,
    contextName,
    assetString,
    canMessage,
    __typename: 'Group',
  }),
}
