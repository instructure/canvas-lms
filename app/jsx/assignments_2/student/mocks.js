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
import {addTypenameToDocument} from 'apollo-utilities'
import gql from 'graphql-tag'
import {graphql} from 'graphql'
import {makeExecutableSchema, addMockFunctionsToSchema} from 'graphql-tools'
import {print} from 'graphql/language/printer'
import schemaString from '../../../../schema.graphql'

import {Assignment, AssignmentDefaultMocks} from './graphqlData/Assignment'
import {AssignmentGroupDefaultMocks} from './graphqlData/AssignmentGroup'
import {ErrorDefaultMocks} from './graphqlData/Error'
import {ExternalToolDefaultMocks} from './graphqlData/ExternalTool'
import {FileDefaultMocks} from './graphqlData/File'
import {LockInfoDefaultMocks} from './graphqlData/LockInfo'
import {MediaObjectDefaultMocks} from './graphqlData/MediaObject'
import {MediaSourceDefaultMocks} from './graphqlData/MediaSource'
import {MediaTrackDefaultMocks} from './graphqlData/MediaTrack'
import {ModuleDefaultMocks} from './graphqlData/Module'
import {MutationDefaultMocks} from './graphqlData/Mutations'
import {ProficiencyRatingDefaultMocks} from './graphqlData/ProficiencyRating'
import {RubricAssessmentDefaultMocks} from './graphqlData/RubricAssessment'
import {RubricAssessmentRatingDefaultMocks} from './graphqlData/RubricAssessmentRating'
import {RubricAssociationDefaultMocks} from './graphqlData/RubricAssociation'
import {RubricCriterionDefaultMocks} from './graphqlData/RubricCriterion'
import {RubricDefaultMocks} from './graphqlData/Rubric'
import {RubricRatingDefaultMocks} from './graphqlData/RubricRating'
import {Submission, SubmissionDefaultMocks} from './graphqlData/Submission'
import {SubmissionCommentDefaultMocks} from './graphqlData/SubmissionComment'
import {SubmissionDraftDefaultMocks} from './graphqlData/SubmissionDraft'
import {SubmissionHistoryDefaultMocks} from './graphqlData/SubmissionHistory'
import {SubmissionInterfaceDefaultMocks} from './graphqlData/SubmissionInterface'
import {UserDefaultMocks} from './graphqlData/User'
import {UserGroupsDefaultMocks} from './graphqlData/UserGroups'

function defaultMocks() {
  return {
    // Custom scalar types defined in our graphql schema
    URL: () => 'http://graphql-mocked-url.com',
    DateTime: () => null,

    // Custom mocks for type specific data we are querying
    ...AssignmentDefaultMocks,
    ...AssignmentGroupDefaultMocks,
    ...ErrorDefaultMocks,
    ...ExternalToolDefaultMocks,
    ...FileDefaultMocks,
    ...LockInfoDefaultMocks,
    ...MediaObjectDefaultMocks,
    ...MediaSourceDefaultMocks,
    ...MediaTrackDefaultMocks,
    ...ModuleDefaultMocks,
    ...MutationDefaultMocks,
    ...ProficiencyRatingDefaultMocks,
    ...RubricAssessmentDefaultMocks,
    ...RubricAssessmentRatingDefaultMocks,
    ...RubricAssociationDefaultMocks,
    ...RubricCriterionDefaultMocks,
    ...RubricDefaultMocks,
    ...RubricRatingDefaultMocks,
    ...SubmissionDefaultMocks,
    ...SubmissionCommentDefaultMocks,
    ...SubmissionDraftDefaultMocks,
    ...SubmissionHistoryDefaultMocks,
    ...SubmissionInterfaceDefaultMocks,
    ...UserDefaultMocks,
    ...UserGroupsDefaultMocks
  }
}

function createMocks(overrides = []) {
  const mocks = defaultMocks()
  if (!Array.isArray(overrides)) {
    overrides = [overrides]
  }

  overrides.forEach(overrideObj => {
    if (typeof overrideObj !== 'object') {
      throw new Error(`overrides must be an object, not ${typeof overrideObj}`)
    }
    Object.keys(overrideObj).forEach(key => {
      const defaultFunction = mocks[key] || (() => {})
      const defaultValues = defaultFunction()
      const overrideFunction = overrideObj[key]
      const overrideValues = overrideFunction()
      mocks[key] = () => ({...defaultValues, ...overrideValues})
    })
  })

  return mocks
}

/*
 * Mock the result of a graphql query based on the graphql schema for canvas
 * and some default values set specifically for assignments 2. For specifics,
 * see: https://www.apollographql.com/docs/graphql-tools/mocking/
 *
 * NOTE: You can mock an interface by passing in desired concrete __typename as
 *       an override. For example, if you are using the `Node` interface to
 *       query for a course, your override would look like this:
 *
 *       ```
 *       {
 *         Node: () => ({ __typename: 'Course'})
 *       }
 *       ```
 */
export function mockQuery(query, overrides = [], variables = {}) {
  // Turn the processed / normalized graphql-tag (gql) query back into a
  // string that can be used to make a query using graphql.js. Using gql is
  // super helpful for things like removing duplicate fragments, so we still
  // want to use that when we are defining our queries.
  const queryStr = print(addTypenameToDocument(query))
  const schema = makeExecutableSchema({
    typeDefs: schemaString,
    resolverValidationOptions: {
      requireResolversForResolveType: false
    }
  })
  const mocks = createMocks(overrides)
  addMockFunctionsToSchema({schema, mocks})
  return graphql(schema, queryStr, null, null, variables) // Returns a promise
}

export async function mockAssignment(overrides = []) {
  const query = gql`
    query AssignmentQuery {
      assignment(id: "1") {
        ...Assignment
      }
    }
    ${Assignment.fragment}
  `
  const result = await mockQuery(query, overrides)
  const assignment = result.data.assignment

  // TODO: Move env out of assignment and into react context.
  assignment.env = {
    assignmentUrl: 'mocked-assignment-url',
    courseId: '1',
    currentUser: {id: '1', display_name: 'bob', avatar_url: 'awesome.avatar.url'},
    modulePrereq: null,
    moduleUrl: 'mocked-module-url'
  }
  return assignment
}

export async function mockSubmission(overrides = []) {
  const query = gql`
    query SubmissionQuery($submissionID: ID!) {
      node(id: "1") {
        ... on Submission {
          ...Submission
        }
      }
    }
    ${Submission.fragment}
  `
  if (!Array.isArray(overrides)) {
    overrides = [overrides]
  }
  overrides.push({
    Node: () => ({__typename: 'Submission'})
  })

  const result = await mockQuery(query, overrides, {submissionID: '1'})
  return result.data.node
}

export async function mockAssignmentAndSubmission(overrides = []) {
  const result = await Promise.all([mockAssignment(overrides), mockSubmission(overrides)])
  return {
    assignment: result[0],
    submission: result[1]
  }
}
