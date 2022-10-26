/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {createClient, gql} from '..'

describe('host configuration', () => {
  const someQuery = gql`
    query fakeQuery {
      aField
    }
  `
  const fakeResponse = {
    text: async () => {
      return '{"data": { "aField": "aValue" }, "errors": []}'
    },
  }

  it('builds an apollo client', () => {
    const client = createClient()
    const props = Object.getOwnPropertyNames(client)
    expect(props.includes('query')).toBeTruthy()
    expect(props.includes('mutate')).toBeTruthy()
  })

  it('defaults to a relative URI', async () => {
    const fakeFetch = async (uri, _options) => {
      expect(uri).toEqual('/api/graphql')
      return fakeResponse
    }
    // this passes in a fetch option to the Apollo HttpLink
    // in the client, so instead of actually using a global "fetch"
    // call that would invoke a network connection, we can substitute
    // our assertion above about the uri and return some fake data
    const client = createClient({httpLinkOptions: {fetch: fakeFetch}})
    await client.query({query: someQuery})
  })

  it('accepts an alternate URI for gateway config', async () => {
    const uriTarget = 'http://my-gateway-uri/my/graphql/path'
    const fakeFetch = async (uri, _options) => {
      expect(uri).toEqual(uriTarget)
      return fakeResponse
    }

    // this proves that if we pass in a different uri for link options
    // as part of the client initiatlization, we will actually be sending our request
    // to a different address.
    const client = createClient({httpLinkOptions: {fetch: fakeFetch, uri: uriTarget}})
    await client.query({query: someQuery})
  })

  describe('API gateway override', () => {
    async function fakeGatewayFetch(url, config) {
      switch (url) {
        case '/api/v1/inst_access_tokens': {
          return {
            ok: true,
            status: 200,
            json: async () => ({token: 'my-fake-token'}),
          }
        }
        case 'http://my-gateway/graphql': {
          // make sure token is being sent to api gateway
          expect(config.headers.authorization).toEqual('Bearer my-fake-token')
          return {
            ok: true,
            status: 200,
            text: async () => {
              return '{"data": { "aField": "aValue" }, "errors": []}'
            },
          }
        }
        default: {
          throw new Error(`Unhandled request: ${url}`)
        }
      }
    }

    beforeAll(() => jest.spyOn(global, 'fetch'))

    beforeEach(() => {
      global.fetch.mockImplementation(fakeGatewayFetch)
      global.fetch.mockClear()
    })

    it('talks to gateway URI with InstAccess token', async () => {
      // prove that by introducing one config parameter, the client
      // reconfigures itself to talk there over HTTP and to fetch
      // InstAccess tokens to do so (see expectation in mock'd
      // fetch implementation above)
      const gatewayApolloClient = createClient({apiGatewayUri: 'http://my-gateway/graphql'})
      const gatewayResponse = await gatewayApolloClient.query({query: someQuery})
      expect(gatewayResponse.data.aField).toEqual('aValue')
    })
  })
})
