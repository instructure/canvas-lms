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

import React from 'react'
import {render} from 'react-testing-library'
import gql from 'graphql-tag'
import {Query} from 'react-apollo'
import {cleanupValidationErrors, checkForValidationErrors} from './ValidatedApolloClient'
import ValidatedMockedProvider from './ValidatedMockedProvider'

function testSchema() {
  return `
    type Query {
      things(id: ID, filter: String): [Thing!]
    }

    type Thing {
      name: String!
      serialNumber: String!
    }
  `
}

describe('ValidatedMockedProvider', () => {
  afterEach(() => {
    // Keep the mock client from failing tests in its after each. We're expecting failures.
    cleanupValidationErrors()
  })

  it('succeeds with a valid query', () => {
    const query = gql`
      query GetThing($filter: String) {
        things(filter: $filter) {
          name
        }
      }
    `
    const {getByText} = render(
      <ValidatedMockedProvider schema={testSchema()}>
        <Query query={query} variables={{filter: 'foo'}}>
          {() => {
            return <span>Success!</span>
          }}
        </Query>
      </ValidatedMockedProvider>
    )
    expect(getByText('Success!')).toBeInTheDocument()
  })

  class ErrorBoundary extends React.Component {
    static getDerivedStateFromError() {
      return {hasError: true}
    }

    constructor(props) {
      super(props)
      this.state = {}
    }

    render() {
      if (this.state.hasError) return 'Error!'
      return this.props.children // eslint-disable-line react/prop-types
    }
  }

  describe('supressing console.error', () => {
    // because we expect these tests to cause exceptions during render that React
    // will print even when they are caught. Could make a failing test harder to
    // debug, in which case you should temporarily remove this.
    beforeAll(() => {
      jest.spyOn(console, 'error').mockImplementation(() => {})
    })

    afterAll(() => {
      console.error.mockRestore() // eslint-disable-line no-console
    })

    it('uses a ValidatedApolloClient to validate queries and variable values', () => {
      const query = gql`
        query GetThing($filter: String) {
          things(filter: $filter) {
            name
          }
        }
      `
      expect(() => {
        render(
          <ValidatedMockedProvider schema={testSchema()}>
            <Query query={query} variables={{filter: 42}}>
              {() => {
                return ''
              }}
            </Query>
          </ValidatedMockedProvider>
        )
      }).toThrow('Unable to coerce variable: "filter":')
    })

    it('reports errors for later validation even with an error boundary', () => {
      const query = gql`
        query GetThing($filter: String) {
          things(filter: $filter) {
            name
          }
        }
      `
      const {getByText} = render(
        <ValidatedMockedProvider schema={testSchema()}>
          <ErrorBoundary>
            <Query query={query} variables={{filter: 42}}>
              {() => {
                return <span>Success!</span>
              }}
            </Query>
          </ErrorBoundary>
        </ValidatedMockedProvider>
      )
      expect(getByText('Error!')).toBeInTheDocument()
      // Even with an error boundary, tests can fail by calling this hook in an afterEach.
      expect(() => checkForValidationErrors()).toThrow()
    })
  })
})
