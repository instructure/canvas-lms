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

import {shape, string} from 'prop-types'
import gql from 'graphql-tag'

export const Group = {
  fragment: gql`
    fragment Group on Group {
      _id
      id
      name
    }
  `,
  shape: shape({
    _id: string,
    id: string,
    name: string,
  }),
  mock:
    () =>
    ({_id = '5', id = 'J2n9F08vw6', name = 'Super Group'}) => ({
      _id,
      id,
      name,
      __typename: 'Group',
    }),
}
