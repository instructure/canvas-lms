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

import {AdhocStudents} from './AdhocStudents'
import {Group} from './Group'
import {gql} from '@apollo/client'
import {shape, string, oneOfType} from 'prop-types'

export const AssignmentOverride = {
  fragment: gql`
    fragment AssignmentOverride on AssignmentOverride {
      id
      _id
      dueAt
      lockAt
      unlockAt
      title
      set {
        ... on AdhocStudents {
          ...AdhocStudents
        }
        ... on Group {
          ...Group
        }
      }
    }
    ${AdhocStudents.fragment},
    ${Group.fragment}
  `,

  shape: shape({
    id: string,
    _id: string,
    dueAt: string,
    lockAt: string,
    unlockAt: string,
    title: string,
    set: oneOfType([AdhocStudents.shape, Group.shape]),
  }),

  mock: ({
    id = 'QXNzaWdebTVubC0x',
    _id = '1',
    dueAt = '2021-03-30T23:59:59-06:00',
    lockAt = '2021-04-03T23:59:59-06:00',
    unlockAt = '2021-03-24T00:00:00-06:00',
    title = 'assignment override title',
    set = AdhocStudents.mock(),
  } = {}) => ({
    id,
    _id,
    dueAt,
    lockAt,
    unlockAt,
    title,
    set,
    __typename: 'AssignmentOverride',
  }),
}
