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
import {arrayOf, float, string, number} from 'prop-types'

import {Submission} from './Submission'

export const Assignment = {
  fragment: gql`
    fragment Assignment on Assignment {
      _id
      dueAt(applyOverrides: true)
      htmlUrl
      name
      pointsPossible
      gradingType
      gradingPeriodId
      state
      assignmentGroup {
        _id
        name
        groupWeight
      }
      modules {
        _id
        name
        position
        moduleItems {
          content {
            ... on Assignment {
              _id
              name
            }
          }
        }
      }
    }
    ${Submission.fragment}
  `,
  shape: {
    _id: string,
    dueAt: string,
    htmlUrl: string,
    name: string,
    pointsPossible: float,
    gradingType: string,
    gradingPeriodId: string,
    state: string,
    assignmentGroup: {
      _id: string,
      name: string,
    },
    submissionsConnection: arrayOf({
      nodes: arrayOf(Submission.shape),
    }),
    modules: arrayOf({
      _id: string,
      name: string,
      position: number,
      moduleItems: arrayOf({
        content: {
          _id: string,
          name: string,
        },
      }),
    }),
  },
  mock: ({
    _id = '1',
    dueAt = '2020-01-01T00:00:00Z',
    htmlUrl = 'https://example.com',
    name = 'Assignment 1',
    pointsPossible = 100,
    gradingType = 'points',
    gradingPeriodId = '1',
    state = 'published',
    assignmentGroup = {
      _id: '1',
      name: 'Group 1',
    },
    submissionsConnection = {
      nodes: [Submission.mock()],
    },
    modules = [
      {
        _id: '1',
        name: 'Module A',
        position: 1,
        moduleItems: [
          {
            content: {
              _id: '1',
              name: 'Assignment 1',
            },
          },
        ],
      },
    ],
  } = {}) => ({
    _id,
    dueAt,
    htmlUrl,
    name,
    pointsPossible,
    gradingType,
    gradingPeriodId,
    state,
    assignmentGroup,
    submissionsConnection,
    modules,
  }),
}
