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
import {executeQuery} from '@canvas/query/graphql'
import {RubricQueryResponse} from '../types/Rubric'

const COURSE_RUBRICS_QUERY = gql`
  query CourseRubricsQuery($courseId: ID!) {
    course(id: $courseId) {
      rubricsConnection {
        nodes {
          id: _id
          criteriaCount
          pointsPossible
          title
          workflowState
        }
      }
    }
  }
`

const ACCOUNT_RUBRICS_QUERY = gql`
  query AccountRubricsQuery($accountId: ID!) {
    account(id: $accountId) {
      rubricsConnection {
        nodes {
          id: _id
          criteriaCount
          pointsPossible
          title
          workflowState
        }
      }
    }
  }
`

type AccountRubricsQueryVariables = {
  accountId: string
  courseId?: never
}

type CourseRubricsQueryVariables = {
  accountId?: never
  courseId: string
}

type CourseRubricQueryResponse = {
  course: RubricQueryResponse
}

type AccountRubricQueryResponse = {
  account: RubricQueryResponse
}

export type FetchRubricVariables = AccountRubricsQueryVariables | CourseRubricsQueryVariables

export const fetchCourseRubrics = async (queryVariables: FetchRubricVariables) => {
  const {course} = await executeQuery<CourseRubricQueryResponse>(
    COURSE_RUBRICS_QUERY,
    queryVariables
  )
  return course
}

export const fetchAccountRubrics = async (queryVariables: FetchRubricVariables) => {
  const {account} = await executeQuery<AccountRubricQueryResponse>(
    ACCOUNT_RUBRICS_QUERY,
    queryVariables
  )
  return account
}
