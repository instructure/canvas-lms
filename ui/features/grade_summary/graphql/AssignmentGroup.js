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
import {arrayOf, float, number, string} from 'prop-types'

export const AssignmentGroup = {
  fragment: gql`
    fragment AssignmentGroup on AssignmentGroup {
      _id
      name
      groupWeight
      position
      rules {
        dropHighest
        dropLowest
        neverDrop {
          _id
          name
        }
      }
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
    position: number,
    rules: {
      dropHighest: float,
      dropLowest: float,
      neverDrop: arrayOf({
        _id: string,
        name: string,
      }),
    },
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
    groupWeight = 50,
    position = 1,
    rules = {
      dropHighest: 0,
      dropLowest: 0,
      neverDrop: [{_id: '1', name: 'Assignment 1'}],
    },
    gradesConnection = {
      nodes: [
        {
          currentGrade: 'A',
          currentScore: 90,
          overrideGrade: 'B',
          overrideScore: 80,
        },
      ],
    },
  } = {}) => ({
    _id,
    name,
    groupWeight,
    position,
    rules,
    gradesConnection,
    __typename: 'AssignmentGroup',
  }),
}
