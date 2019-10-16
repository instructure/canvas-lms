/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import getCookie from './shared/helpers/getCookie'
import gql from 'graphql-tag'
import {ApolloClient} from 'apollo-client'
import {InMemoryCache, IntrospectionFragmentMatcher} from 'apollo-cache-inmemory'
import {HttpLink} from 'apollo-link-http'
import {onError} from 'apollo-link-error'
import {ApolloLink} from 'apollo-link'
import {ApolloProvider, Query} from 'react-apollo'
import introspectionQueryResultData from './fragmentTypes.json'
import {withClientState} from 'apollo-link-state'

function createConsoleErrorReportLink() {
  return onError(({graphQLErrors, networkError}) => {
    if (graphQLErrors)
      graphQLErrors.map(({message, locations, path}) =>
        console.log(`[GraphQL error]: Message: ${message}, Location: ${locations}, Path: ${path}`)
      )
    if (networkError) console.log(`[Network error]: ${networkError}`)
  })
}

function setHeadersLink() {
  return new ApolloLink((operation, forward) => {
    operation.setContext({
      headers: {
        'X-Requested-With': 'XMLHttpRequest',
        'GraphQL-Metrics': true,
        'X-CSRF-Token': getCookie('_csrf_token')
      }
    })
    return forward(operation)
  })
}

function createHttpLink() {
  return new HttpLink({
    uri: '/api/graphql',
    credentials: 'same-origin'
  })
}

function createCache() {
  return new InMemoryCache({
    addTypename: true,
    dataIdFromObject: object => object.id || null,
    fragmentMatcher: new IntrospectionFragmentMatcher({
      introspectionQueryResultData
    })
  })
}

function createClient(opts = {}) {
  const cache = createCache()
  const defaults = opts.defaults || {}
  const resolvers = opts.resolvers || {}
  const stateLink = withClientState({
    cache,
    resolvers,
    defaults
  })

  const links =
    createClient.mockLink == null
      ? [createConsoleErrorReportLink(), setHeadersLink(), stateLink, createHttpLink()]
      : [createConsoleErrorReportLink(), stateLink, createClient.mockLink]

  const client = new ApolloClient({
    link: ApolloLink.from(links),
    cache
  })

  return client
}

export {createClient, gql, ApolloProvider, Query, createCache}
