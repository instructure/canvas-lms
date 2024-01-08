/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {string} from 'prop-types'
import gql from 'graphql-tag'

export const AssignmentOverride = {
  fragment: gql`
    fragment AssignmentOverride on AssignmentOverride {
      _id
      id
      dueAt
      lockAt
      unlockAt
      set {
        ... on AdhocStudents {
          __typename
          students {
            _id
            id
          }
        }
        ... on Course {
          __typename
          id
          name
          _id
        }
        ... on Section {
          __typename
          id
          _id
          name
        }
        ... on Noop {
          __typename
          _id
        }
        ... on Group {
          id
          name
          _id
        }
      }
    }
  `,
  shape: () => ({
    _id: string,
    id: string,
    dueAt: string,
    lockAt: string,
    unlockAt: string,
  }),
  mock: ({
    _id = '1',
    id = '1',
    dueAt = '2020-01-01',
    lockAt = '2020-01-01',
    unlockAt = '2020-01-01',
    set = {
      __typename: 'Section',
      id: '1',
      name: 'Section Name',
      _id: '1',
    },
  } = {}) => ({
    _id,
    id,
    dueAt,
    lockAt,
    unlockAt,
    set,
  }),
}
