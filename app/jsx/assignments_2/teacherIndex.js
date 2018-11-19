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

import React from 'react'
import ReactDOM from 'react-dom'
import ApolloClient from 'apollo-boost'
import {ApolloProvider} from 'react-apollo'

import TeacherView from './teacher/components/TeacherView'

const apolloClient = new ApolloClient({
  uri: '/api/graphql',
  request: operation => {
    operation.setContext({
      headers: {
        'X-Requested-With': 'XMLHttpRequest',
        'GraphQL-Metrics': true,
        'X-CSRF-Token': $.cookie('_csrf_token')
      }
    })
  }
})

export default function renderAssignmentsApp(env, elt) {
  ReactDOM.render(
    <ApolloProvider client={apolloClient}>
      <TeacherView assignmentLid={ENV.ASSIGNMENT_ID.toString()} />
    </ApolloProvider>,
    elt
  )
}
