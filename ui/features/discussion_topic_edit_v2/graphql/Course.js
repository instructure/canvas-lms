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

import {GroupSet} from './GroupSet'
import {Section} from './Section'
import {arrayOf, shape, string} from 'prop-types'
import gql from 'graphql-tag'

export const Course = {
  fragment: gql`
    fragment Course on Course {
      _id
      id
      name
      enrollmentsConnection {
        nodes {
          user {
            name
            courseRoles(roleTypes: "StudentEnrollment")
          }
        }
      }
      groupSetsConnection {
        nodes {
          _id
          name
        }
      }
      sectionsConnection {
        nodes {
          _id
          name
        }
      }
    }
  `,
  shape: shape({
    _id: string,
    id: string,
    name: string,
    enrollmentsConnection: shape({
      nodes: arrayOf({
        user: {
          name: string,
          courseRoles: arrayOf(string),
        },
      }),
    }),
    groupSetsConnection: shape({
      nodes: arrayOf(GroupSet.shape),
    }),
    sectionsConnection: shape({
      nodes: arrayOf(Section.shape),
    }),
  }),
  mock: {
    _id: '1',
    id: 'K3n9F08vw4',
    name: 'X-Men School',
    enrollmentsConnection: shape({
      nodes: [
        {
          user: {
            name: 'Albert Einstein',
            courseRoles: ['StudentEnrollment'],
          },
        },
      ],
    }),
    groupsConnection: shape({
      nodes: [GroupSet.mock()],
    }),
    sectionsConnection: shape({
      nodes: [Section.mock()],
    }),
  },
}
