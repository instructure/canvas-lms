/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import glob from 'glob'
import gql from 'graphql-tag'

import {Assignment} from './student/Assignment'
import {Submission} from './student/Submission'

import mockGraphqlQuery from '@canvas/graphql-query-mock'

// Dynamically load and cache all of the `DefaultMocks` defined in `./student/*.js`
let _dynamicDefaultMockImports = null
async function loadDefaultMocks() {
  if (_dynamicDefaultMockImports !== null) {
    return _dynamicDefaultMockImports
  }

  const filesToImport = glob.sync('./student/**.js', {cwd: './ui/shared/assignments/graphql'})
  const defaultMocks = await Promise.all(
    filesToImport.map(async file => {
      const fileImport = await import(file)
      return fileImport.DefaultMocks || {}
    })
  )
  _dynamicDefaultMockImports = defaultMocks.filter(m => m !== undefined)
  return _dynamicDefaultMockImports
}

const SUBMISSION_QUERY = gql`
  query SubmissionQuery($submissionID: ID!) {
    submission(id: "1") {
      ...Submission
    }
  }
  ${Submission.fragment}
`

const ASSIGNMENT_QUERY = gql`
  query AssignmentQuery {
    assignment(id: "1") {
      ...Assignment
      rubric {
        id
      }
    }
  }
  ${Assignment.fragment}
`

// Small wrapper around mockGraphqlQuery which includes our default overrides
export async function mockQuery(queryAST, overrides = [], variables = {}) {
  if (!Array.isArray(overrides)) {
    overrides = [overrides]
  }
  const defaultOverrides = await loadDefaultMocks()
  const allOverrides = [...defaultOverrides, ...overrides]
  return mockGraphqlQuery(queryAST, allOverrides, variables)
}

export async function mockAssignment(overrides = []) {
  const result = await mockQuery(ASSIGNMENT_QUERY, overrides)
  const assignment = result.data.assignment

  // TODO: Move env out of assignment and into react context.
  assignment.env = {
    assignmentUrl: 'mocked-assignment-url',
    courseId: '1',
    currentUser: {id: '1', display_name: 'bob', avatar_image_url: 'awesome.avatar.url'},
    enrollmentState: 'active',
    modulePrereq: null,
    moduleUrl: 'mocked-module-url',
  }
  return assignment
}

export async function mockSubmission(overrides = []) {
  const result = await mockQuery(SUBMISSION_QUERY, overrides, {submissionID: '1'})
  return result.data.submission
}

export async function mockAssignmentAndSubmission(overrides = []) {
  const result = await Promise.all([mockAssignment(overrides), mockSubmission(overrides)])
  return {
    assignment: result[0],
    submission: result[1],
    onChangeSubmission: () => {},
  }
}
