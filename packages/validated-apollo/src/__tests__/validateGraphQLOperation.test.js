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
import {validateGraphQLOperation} from '../validateGraphQLOperation'

const testSchema = buildSchema(`
    type Query {
      things(id: ID, orderBy: ThingOrderBy, filter: String): [Thing!]
    }

    type Mutation {
      setThingName(id: ID!, name: String!): Thing!
    }

    type Thing {
      name: String!
      serialNumber: String!
    }

    input ThingOrderBy {
      field: OrderableThingField!
      direction: OrderDirection
    }

    enum OrderableThingField {
      name
      serialNumber
    }

    enum OrderDirection {
      ascending
      descending
    }
`)

describe('validateGraphQLOperation', () => {
  it('returns an empty array if a query with no variables is valid', () => {
    const query = gql`
      query GetThings {
        things(id: 42) {
          name
        }
      }
    `
    expect(validateGraphQLOperation(testSchema, query)).toHaveLength(0)
  })

  it('returns an empty array if a query with variables is valid', () => {
    const query = gql`
      query GetThing($id: ID!) {
        things(id: $id) {
          name
        }
      }
    `
    expect(validateGraphQLOperation(testSchema, query, {id: '42'})).toHaveLength(0)
  })

  it('reports if the query does not validate against the schema', () => {
    // Bad query because $orderBy's type (String) does not match the expected type in the schema (ThingOrderBy)
    const query = gql`
      query GetThings {
        things {
          nonThingField
        }
      }
    `
    const errs = validateGraphQLOperation(testSchema, query)
    expect(errs).toHaveLength(1)
    expect(errs[0].message).toMatch('Cannot query field "nonThingField"')
  })

  it('reports if the variable values do not validate against the declared variable types', () => {
    const query = gql`
      query GetThing($orderBy: ThingOrderBy) {
        things(orderBy: $orderBy) {
          name
        }
      }
    `
    // the value for field is not in the enum
    const variables = {orderBy: {field: 'badField'}}
    expect(validateGraphQLOperation(testSchema, query, variables)[0].message).toMatch(
      'Unable to coerce variable: "orderBy":'
    )
  })

  it('reports if there are extra variables not declared in the query', () => {
    const query = gql`
      query GetThing {
        things {
          name
        }
      }
    `
    const variables = {extra: 'extra variable'}
    expect(validateGraphQLOperation(testSchema, query, variables)[0].message).toMatch(
      'Extra variable passed to graphql operation: "extra"'
    )
  })

  it('reports if a non-nullable variable is missing', () => {
    const query = gql`
      query GetThing($id: ID!, $filter: String) {
        things(id: $id, filter: $filter) {
          name
        }
      }
    `
    const variables = {}
    expect(validateGraphQLOperation(testSchema, query, variables)[0].message).toMatch(
      'Unable to coerce variable: "id":'
    )
  })

  it('reports if a non-nullable variable is null', () => {
    const query = gql`
      query GetThing($id: ID!, $filter: String) {
        things(id: $id, filter: $filter) {
          name
        }
      }
    `
    const variables = {id: null}
    expect(validateGraphQLOperation(testSchema, query, variables)[0].message).toMatch(
      'Unable to coerce variable: "id":'
    )
  })

  it('does not report if optional variables are missing', () => {
    const query = gql`
      query GetThing($filter: String) {
        things(filter: $filter) {
          name
        }
      }
    `
    const variables = {}
    expect(validateGraphQLOperation(testSchema, query, variables)).toHaveLength(0)
  })

  it('does not report if optional variables are null', () => {
    const query = gql`
      query GetThing($filter: String) {
        things(filter: $filter) {
          name
        }
      }
    `
    const variables = {filter: null}
    expect(validateGraphQLOperation(testSchema, query, variables)).toHaveLength(0)
  })

  it('validates mutations', () => {
    const query = gql`
      mutation SetThing($id: ID!, $name: String!) {
        setThingName(id: $id, name: $name) {
          name
        }
      }
    `
    const variables = {id: '42', name: 1234}
    expect(validateGraphQLOperation(testSchema, query, variables)[0].message).toMatch(
      'Unable to coerce variable: "name":'
    )
  })
})
