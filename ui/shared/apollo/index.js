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

import getCookie from '@instructure/get-cookie'
import gql from 'graphql-tag'
import {ApolloClient} from 'apollo-client'
import {InMemoryCache, IntrospectionFragmentMatcher} from 'apollo-cache-inmemory'
import {persistCache} from 'apollo-cache-persist'
import {HttpLink} from 'apollo-link-http'
import {onError} from 'apollo-link-error'
import {ApolloLink} from 'apollo-link'
import {ApolloProvider, Query} from 'react-apollo'
import introspectionQueryResultData from './fragmentTypes.json'
import {withClientState} from 'apollo-link-state'
import InstAccess from './InstAccess'

import EncryptedForage from '../encrypted-forage'

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

function createHttpLink(httpLinkOptions = {}) {
  const defaultOptions = {
    uri: '/api/graphql',
    credentials: 'same-origin'
  }
  const linkOpts = {
    ...defaultOptions,
    ...httpLinkOptions
  }
  return new HttpLink(linkOpts)
}

function createCache() {
  return new InMemoryCache({
    addTypename: true,
    dataIdFromObject: object => {
      let cacheKey

      if (object.id) {
        cacheKey = object.id
      } else if (object._id && object.__typename) {
        cacheKey = object.__typename + object._id
      } else {
        return null
      }

      // Multiple distinct RubricAssessments (and likely other versionable
      // objects) may be represented by the same ID and type. Add the
      // artifactAttempt field to the cache key to assessments for different
      // attempts don't collide.
      if (object.__typename === 'RubricAssessment' && object.artifactAttempt != null) {
        cacheKey = `${cacheKey}:${object.artifactAttempt}`
      }
      return cacheKey
    },
    fragmentMatcher: new IntrospectionFragmentMatcher({
      introspectionQueryResultData
    })
  })
}

async function createPersistentCache(passphrase = null) {
  const cache = createCache()
  await persistCache({
    cache,
    storage: new EncryptedForage(passphrase)
  })
  return cache
}

function createClient(opts = {}) {
  const cache = opts.cache || createCache()
  const defaults = opts.defaults || {}
  const resolvers = opts.resolvers || {}
  const stateLink = withClientState({
    cache,
    resolvers,
    defaults
  })

  // if this option exists, we want this client
  // to talk through the API gateway instead of
  // directly to canvas, so we'll need to update the http
  // link to have both our target URL, and also
  // an enhanced "fetch" implementation that uses
  // InstAccess tokens
  const gatewayUri = opts.apiGatewayUri || false
  const defaultHttpLinkOptions = {}
  if (gatewayUri) {
    defaultHttpLinkOptions.uri = gatewayUri
    const instAccess = new InstAccess()
    defaultHttpLinkOptions.fetch = (uri, fetchOpts) => {
      return instAccess.gatewayAuthenticatedFetch(uri, fetchOpts)
    }
  }

  // there are some cases where we need to override these options.
  //  If we're using an API gateway instead of talking to canvas directly,
  // we need to be able to inject that config.
  // also if we need to test what the client is sending over the wire,
  // being able to override the "fetch" method is useful.
  // A design goal here is not to do anything "special", but just
  // use the options that are already built into ApolloLink:
  // https://github.com/apollographql/apollo-client/blob/main/src/link/core/ApolloLink.ts
  const httpLinkOptions = {
    ...defaultHttpLinkOptions,
    ...(opts.httpLinkOptions || {})
  }

  const links =
    createClient.mockLink == null
      ? [
          createConsoleErrorReportLink(),
          setHeadersLink(),
          stateLink,
          createHttpLink(httpLinkOptions)
        ]
      : [createConsoleErrorReportLink(), stateLink, createClient.mockLink]

  const client = new ApolloClient({
    link: ApolloLink.from(links),
    cache
  })

  return client
}

export {createClient, gql, ApolloProvider, Query, createCache, createPersistentCache}
