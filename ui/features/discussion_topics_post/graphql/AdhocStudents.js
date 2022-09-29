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

import {arrayOf, shape, string} from 'prop-types'
import gql from 'graphql-tag'

export const Student = {
  shape: shape({
    shortName: string,
  }),

  mock: ({shortName = 'Rick Sanchez'} = {}) => ({
    shortName,
    __typename: 'User',
  }),
}

export const AdhocStudents = {
  fragment: gql`
    fragment AdhocStudents on AdhocStudents {
      students {
        shortName
      }
    }
  `,

  shape: shape({
    students: arrayOf(Student.shape),
  }),

  mock: ({
    students = [
      Student.mock(),
      Student.mock({shortName: 'Morty Smith'}),
      Student.mock({shortName: 'Jerry Smith'}),
      Student.mock({shortName: 'Beth Smith'}),
      Student.mock({shortName: 'Summer Smith'}),
    ],
  } = {}) => ({
    students,
    __typename: 'AdhocStudents',
  }),
}
