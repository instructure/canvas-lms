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
import {arrayOf, bool, string, number} from 'prop-types'

import {GradingStandard} from './GradingStandard'
import {Submission} from './Submission'
import {Rubric} from '@canvas/assignments/graphql/student/Rubric'
import {RubricAssociation} from '@canvas/assignments/graphql/student/RubricAssociation'

export const Assignment = {
  fragment: gql`
    fragment Assignment on Assignment {
      _id
      allowedAttempts
      createdAt
      htmlUrl
      assignmentGroupId
      dueAt
      gradeGroupStudentsIndividually
      gradesPublished
      gradingPeriodId
      gradingType
      gradingStandard {
        ...GradingStandard
      }
      groupCategoryId
      hasSubmittedSubmissions
      lockAt
      name
      omitFromFinalGrade
      pointsPossible
      position
      published
      state
      unlockAt
      updatedAt
      assignmentGroup {
        _id
        name
        groupWeight
      }
      scoreStatistic {
        count
        lowerQ
        maximum
        mean
        median
        minimum
        upperQ
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
      rubric {
        ...Rubric
      }
      rubricAssociation {
        ...RubricAssociation
      }
    }
    ${GradingStandard.fragment}
    ${Rubric.fragment}
    ${RubricAssociation.fragment}
    ${Submission.fragment}
  `,
  shape: {
    _id: string,
    allowedAttempts: number,
    createdAt: string,
    htmlUrl: string,
    assignmentGroupId: string,
    dueAt: string,
    gradeGroupStudentsIndividually: bool,
    gradesPublished: bool,
    gradingPeriodId: string,
    gradingType: string,
    gradingStandard: GradingStandard.shape,
    groupCategoryId: string,
    hasSubmittedSubmissions: bool,
    lockAt: string,
    name: string,
    omitFromFinalGrade: bool,
    pointsPossible: number,
    position: number,
    published: bool,
    state: string,
    unlockAt: string,
    updatedAt: string,
    assignmentGroup: {
      _id: string,
      name: string,
    },
    scoreStatistic: {
      count: number,
      lowerQ: number,
      maximum: number,
      mean: number,
      median: number,
      minimum: number,
      upperQ: number,
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
    rubric: Rubric.shape,
    rubricAssociation: RubricAssociation.shape,
  },
  mock: ({
    _id = '1',
    allowedAttempts = 1,
    createdAt = '2020-01-01T00:00:00Z',
    htmlUrl = 'https://example.com',
    assignmentGroupId = '1',
    dueAt = '2020-01-01T00:00:00Z',
    gradeGroupStudentsIndividually = false,
    gradesPublished = false,
    gradingPeriodId = '1',
    gradingType = 'points',
    gradingStandard = GradingStandard.mock(),
    groupCategoryId = '1',
    hasSubmittedSubmissions = true,
    lockAt = null,
    name = 'Assignment 1',
    omitFromFinalGrade = false,
    pointsPossible = 100,
    position = 1,
    published = true,
    state = 'published',
    unlockAt = null,
    updatedAt = '2020-01-01T00:00:00Z',
    assignmentGroup = {
      _id: '1',
      name: 'Group 1',
    },
    scoreStatistic = {
      count: 1,
      lowerQ: 1,
      maximum: 1,
      mean: 1,
      median: 1,
      minimum: 1,
      upperQ: 1,
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
    rubric = Rubric.mock(),
    rubricAssociation = RubricAssociation.mock(),
  } = {}) => ({
    _id,
    allowedAttempts,
    createdAt,
    htmlUrl,
    assignmentGroupId,
    dueAt,
    gradeGroupStudentsIndividually,
    gradesPublished,
    gradingPeriodId,
    gradingType,
    gradingStandard,
    groupCategoryId,
    hasSubmittedSubmissions,
    lockAt,
    name,
    omitFromFinalGrade,
    pointsPossible,
    position,
    published,
    state,
    unlockAt,
    updatedAt,
    assignmentGroup,
    scoreStatistic,
    submissionsConnection,
    modules,
    rubric,
    rubricAssociation,
  }),
}
