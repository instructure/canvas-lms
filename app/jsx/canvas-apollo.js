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

import $ from 'jquery'
import gql from 'graphql-tag'
import ApolloClient from 'apollo-boost'
import {InMemoryCache} from 'apollo-cache-inmemory'
import {ApolloProvider, Query} from 'react-apollo'

const client = new ApolloClient({
  uri: '/api/graphql',
  request: operation => {
    operation.setContext({
      headers: {
        'X-Requested-With': 'XMLHttpRequest',
        'GraphQL-Metrics': true,
        'X-CSRF-Token': $.cookie('_csrf_token')
      }
    })
  },
  cache: new InMemoryCache({
    addTypename: true,
    dataIdFromObject: object => object.id || null
  })
})

export {client, gql, ApolloProvider, Query}
