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
import {arrayOf, float, string} from 'prop-types'

export const AssignmentGroup = {
  fragment: gql`
    fragment AssignmentGroup on AssignmentGroup {
      _id
      name
      groupWeight
      gradesConnection {
        nodes {
          currentGrade
          currentScore
          overrideGrade
          overrideScore
        }
      }
    }
  `,
  shape: {
    _id: string,
    name: string,
    groupWeight: float,
    gradesConnection: arrayOf({
      nodes: arrayOf({
        currentGrade: string,
        currentScore: float,
        overrideGrade: string,
        overrideScore: float,
      }),
    }),
  },
  mock: ({
    _id = '1',
    name = 'Group 1',
    groupWeight = 0.5,
    gradesConnection = {
      nodes: [
        {
          currentGrade: 'A',
          currentScore: 90,
          overrideGrade: 'B',
          overrideScore: 80,
        },
        {
          currentGrade: 'B',
          currentScore: 80,
          overrideGrade: 'C',
          overrideScore: 70,
        },
      ],
    },
  } = {}) => ({
    _id,
    name,
    groupWeight,
    gradesConnection,
    __typename: 'AssignmentGroup',
  }),
}
