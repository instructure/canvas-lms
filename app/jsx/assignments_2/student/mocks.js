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

import {Assignment} from './graphqlData/Assignment'
import {Submission} from './graphqlData/Submission'

import glob from 'glob'

const filesToImport = glob.sync('./graphqlData/**.js', {cwd: './app/jsx/assignments_2/student'})
const importPromises = filesToImport.map(async file => {
  const fileImport = await import(file)
  return fileImport.DefaultMocks || {}
})

async function makeDefaultMocks() {
  const defaultMockImports = await Promise.all(importPromises)
  return [
    // Custom scalar types defined in our graphql schema
    {URL: () => 'http://graphql-mocked-url.com'},
    {DateTime: () => null},

    // DefaultMocks as defined in the ./graphqlData javascript files
    ...defaultMockImports
  ]
}

async function createMocks(overrides = []) {
  const mocks = {}
  if (!Array.isArray(overrides)) {
    overrides = [overrides]
  }

  const defaultMocks = await makeDefaultMocks()
  const allOverrides = [...defaultMocks, ...overrides]
  allOverrides.forEach(overrideObj => {
    if (typeof overrideObj !== 'object') {
      throw new Error(`overrides must be an object, not ${typeof overrideObj}`)
    }
    Object.keys(overrideObj).forEach(key => {
      const defaultFunction = mocks[key] || (() => undefined)
      const defaultValues = defaultFunction()
      const overrideFunction = overrideObj[key]
      const overrideValues = overrideFunction()

      // This if statement handles scalar types. For example, saying that all URL
      // types resolve to a dummy url, regardless of where they show up in the query
      if (typeof overrideValues !== 'object' || overrideValues === null) {
        mocks[key] = () => overrideValues
      } else {
        mocks[key] = () => ({...defaultValues, ...overrideValues})
      }
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
export async function mockQuery(query, overrides = [], variables = {}) {
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
  const mocks = await createMocks(overrides)
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
