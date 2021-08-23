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

import {buildSchema} from 'graphql'
import gql from 'graphql-tag'
import ValidatedApolloClient, {
  currentValidationErrors,
  cleanupValidationErrors,
  checkForValidationErrors
} from '../ValidatedApolloClient'

function testSchema() {
  return `
    type Query {
      things(id: ID, filter: String): [Thing!]
    }

    type Mutation {
      setThingName(id: ID!, name: String!): Thing!
    }

    type Thing {
      name: String!
      serialNumber: String!
    }
  `
}

function mockClient({query, variables, schema = testSchema()} = {}) {
  const mocks = []
  if (query) {
    mocks.push({request: {query, variables}, result: {}})
  }
  return new ValidatedApolloClient({schema, mocks})
}

describe('ValidatedApolloClient', () => {
  afterEach(() => {
    // Keep the mock client from failing tests in its after each. We're expecting failures.
    cleanupValidationErrors()
  })

  it('does not throw if the query is valid', () => {
    const query = gql`
      query GetThings {
        things(id: 42) {
          name
        }
      }
    `
    expect(() => mockClient({query}).query({query})).not.toThrow()
    expect(currentValidationErrors).toHaveLength(0)
  })

  it('allows a string or a parsed schema as the schema option', () => {
    const query = gql`
      {
        things {
          name
        }
      }
    `
    const schema = buildSchema(testSchema())
    expect(() => mockClient({query, schema}).query({query})).not.toThrow()
  })

  describe('storing validation errors for later use', () => {
    const requiredFilterQuery = gql`
      query GetThings($filter: String!) {
        things(filter: $filter) {
          name
        }
      }
    `

    it('also stores errors for later use', () => {
      expect(currentValidationErrors()).toHaveLength(0)
      expect(() => checkForValidationErrors()).not.toThrow()
      expect(() => mockClient().query({query: requiredFilterQuery})).toThrow('non-nullable')
      expect(currentValidationErrors()).toHaveLength(1)
      expect(() => checkForValidationErrors()).toThrow('non-nullable')
      expect(currentValidationErrors()).toHaveLength(0)
    })

    it('throws only the errors for the latest call to query', () => {
      const client = mockClient()
      expect(() => client.query({query: requiredFilterQuery})).toThrow('non-nullable')
      const variables = {filter: 1234}
      let err
      try {
        client.query({query: requiredFilterQuery, variables})
      } catch (e) {
        err = e
      }
      expect(err.message).not.toMatch(/non-nullable/)
      expect(err.message).toMatch(/coerce/)
      expect(currentValidationErrors()).toHaveLength(2)
    })

    it('combines errors from multiple clients', () => {
      expect(() => mockClient().query({query: requiredFilterQuery})).toThrow()
      expect(() => mockClient().query({query: requiredFilterQuery})).toThrow()
      expect(currentValidationErrors()).toHaveLength(2)
    })

    it('only keep the last 100 errors to prevent large memory leaks', () => {
      const client = mockClient()
      for (let i = 0; i < 105; ++i) {
        expect(() => client.query({query: requiredFilterQuery})).toThrow()
      }
      expect(currentValidationErrors()).toHaveLength(100)
    })
  })

  it('reports multiple violations', () => {
    const query = gql`
      query GetThing($id: ID!, $filter: String) {
        things(id: $id, filter: $filter) {
          name
        }
      }
    `
    const variables = {filter: 42}
    try {
      mockClient().query({query, variables})
      throw new Error('Expected query to throw')
    } catch (e) {
      expect(e.message).toMatch('Unable to coerce variable: "filter":')
      expect(e.message).toMatch('Unable to coerce variable: "id":')
    }
  })

  it('validates on watchQuery', () => {
    const query = gql`
      query GetThing {
        things {
          name
        }
      }
    `
    const variables = {extra: 'extra variable'}
    expect(() => mockClient().watchQuery({query, variables})).toThrow(
      'Extra variable passed to graphql operation: "extra"'
    )
  })

  it('validates on mutation', () => {
    const query = gql`
      mutation SetThingName($id: ID!, $name: String!) {
        setThingName(id: $id, name: $name) {
          name
        }
      }
    `
    const variables = {id: '42', name: 1234}
    expect(() => mockClient().mutate({query, variables})).toThrow(
      'Unable to coerce variable: "name":'
    )
  })
})
