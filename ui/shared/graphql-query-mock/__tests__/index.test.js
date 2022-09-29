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
import gql from 'graphql-tag'
import mockGraphqlQuery from '../index'

const BASIC_QUERY = gql`
  query TestQuery {
    assignment(id: "1") {
      name
    }
  }
`

describe('graphqlMockQuery', () => {
  describe('basic usage', () => {
    it('returns mocked data for a query', async () => {
      const result = await mockGraphqlQuery(BASIC_QUERY)
      expect(result.data.assignment.name).toEqual('Hello World')
    })

    it('lets you use a string instead of gql generated AST to make mack queries', async () => {
      const query = `
        query TestQuery {
          assignment(id: "1") {
            name
          }
        }
      `
      const result = await mockGraphqlQuery(query)
      expect(result.data.assignment.name).toEqual('Hello World')
    })
  })

  describe('overriding data', () => {
    it('works for leaf nodes', async () => {
      const result = await mockGraphqlQuery(BASIC_QUERY, {Assignment: {name: 'foobarbaz'}})
      expect(result.data.assignment.name).toEqual('foobarbaz')
    })

    it('works for scalars', async () => {
      const result = await mockGraphqlQuery(BASIC_QUERY, {String: 'foobarbaz'})
      expect(result.data.assignment.name).toEqual('foobarbaz')
    })

    it('works for lists', async () => {
      const query = gql`
        query TestQuery {
          assignment(id: "1") {
            submissionsConnection {
              nodes {
                _id
              }
            }
          }
        }
      `
      const overrides = [
        {
          SubmissionConnection: {
            nodes: [{_id: '1'}, {_id: '2'}, {_id: '123'}],
          },
        },
      ]
      const result = await mockGraphqlQuery(query, overrides)
      const ids = result.data.assignment.submissionsConnection.nodes.map(s => s._id)
      expect(ids).toEqual(['1', '2', '123'])
    })

    it('can be null for nullable fields', async () => {
      const result = await mockGraphqlQuery(BASIC_QUERY, {Assignment: {name: null}})
      expect(result.data.assignment.name).toEqual(null)
    })

    it('does not let you override non-nullable fileds to null', async () => {
      const query = gql`
        query TestQuery {
          assignment(id: "1") {
            _id
          }
        }
      `
      const promise = mockGraphqlQuery(query, {Assignment: {_id: null}})
      await expect(promise).rejects.toThrow(/The graphql query contained errors/)
    })
  })

  describe('deep merging', () => {
    it('merges multiple different overrides', async () => {
      const query = `
        query TestQuery {
          assignment(id: "1") {
            _id
            name
          }
        }
      `
      const overrides = [{Assignment: {_id: '1'}}, {Assignment: {name: 'foobarbaz'}}]
      const result = await mockGraphqlQuery(query, overrides)
      expect(result.data.assignment._id).toEqual('1')
      expect(result.data.assignment.name).toEqual('foobarbaz')
    })

    it('deep merges multiple different overrides', async () => {
      const query = `
        query TestQuery {
          assignment(id: "1") {
            rubric {
              _id
              title
            }
          }
        }
      `
      const overrides = [
        {Assignment: {rubric: {_id: '1'}}},
        {Assignment: {rubric: {title: 'foobarbaz'}}},
      ]
      const result = await mockGraphqlQuery(query, overrides)
      expect(result.data.assignment.rubric._id).toEqual('1')
      expect(result.data.assignment.rubric.title).toEqual('foobarbaz')
    })

    it('lets you override an already overridden list with an empty list', async () => {
      const query = gql`
        query TestQuery {
          assignment(id: "1") {
            submissionsConnection {
              nodes {
                _id
              }
            }
          }
        }
      `
      const overrides = [
        {SubmissionConnection: {nodes: [{_id: '1'}]}},
        {SubmissionConnection: {nodes: []}},
      ]
      const result = await mockGraphqlQuery(query, overrides)
      expect(result.data.assignment.submissionsConnection.nodes).toEqual([])
    })

    it('handles deep merging of null', async () => {
      const query = gql`
        query TestQuery {
          assignment(id: "1") {
            submissionsConnection {
              nodes {
                url
              }
            }
          }
        }
      `
      const overrides = [
        {SubmissionConnection: {nodes: [{url: 'http://foobarbaz.com'}]}},
        {SubmissionConnection: {nodes: [{url: null}]}},
      ]
      const result = await mockGraphqlQuery(query, overrides)
      const urls = result.data.assignment.submissionsConnection.nodes.map(s => s.url)
      expect(urls).toEqual([null])
    })

    it('handles deep merging of undefined', async () => {
      const query = gql`
        query TestQuery {
          assignment(id: "1") {
            submissionsConnection {
              nodes {
                url
              }
            }
          }
        }
      `
      const overrides = [
        {SubmissionConnection: {nodes: [{url: 'http://foobarbaz.com'}]}},
        {SubmissionConnection: {nodes: [{url: undefined}]}},
      ]
      const result = await mockGraphqlQuery(query, overrides)
      const urls = result.data.assignment.submissionsConnection.nodes.map(s => s.url)
      expect(urls).toEqual(['http://graphql-mocked-url.com']) // Goes back to the default scalar mock
    })
  })

  describe('catches common mistakes by', () => {
    it('raising an error if you try to use invalid override types', async () => {
      const promise = mockGraphqlQuery(BASIC_QUERY, 'string is not valid override')
      await expect(promise).rejects.toThrow(/overrides must be an object/)
    })

    it('raising an error if an override is an invalid graphql type', async () => {
      const promise = mockGraphqlQuery(BASIC_QUERY, {FOOBAR: {name: '1'}})
      await expect(promise).rejects.toThrow(/not a valid graphql type/)
    })

    it('raising an error if querying for a type that does not exist', async () => {
      const query = gql`
        query TestQuery {
          banana {
            _id
          }
        }
      `
      const promise = mockGraphqlQuery(query)
      await expect(promise).rejects.toThrow(/The graphql query contained errors/)
    })

    it('raising an error if querying for a leaf node that does not exist', async () => {
      const query = gql`
        query TestQuery {
          assignment {
            banana
          }
        }
      `
      const promise = mockGraphqlQuery(query)
      await expect(promise).rejects.toThrow(/The graphql query contained errors/)
    })

    it('raising an error if node type was not properly mocked', async () => {
      const query = gql`
        query TestQuery {
          node(id: "1") {
            ... on Assignment {
              name
            }
          }
        }
      `
      const promise = mockGraphqlQuery(query)
      await expect(promise).rejects.toThrow(/must add a __typename override/)
    })
  })

  describe('variables', () => {
    it('can be passed in to a query', async () => {
      const query = gql`
        query TestQuery($assignmentID: ID!) {
          assignment(id: $assignmentID) {
            name
          }
        }
      `
      const result = await mockGraphqlQuery(query, [], {assignmentID: '1'})
      expect(result.data.assignment.name).toEqual('Hello World')
    })

    it('will raise an error if misssing', async () => {
      const query = gql`
        query TestQuery($assignmentID: ID!) {
          assignment(id: $assignmentID) {
            name
          }
        }
      `
      const promise = mockGraphqlQuery(query)
      await expect(promise).rejects.toThrow(/The graphql query contained errors/)
    })
  })
})
