/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import ReactDOM from 'react-dom'
import {ApolloProvider} from '@apollo/react-common'
import TeacherQuery from './components/TeacherQuery'
import {createClient} from '@canvas/apollo-v3'
import {ApolloClient} from 'apollo-client'
import type {InMemoryCache} from 'apollo-cache-inmemory'

export default function renderAssignmentsApp(elt: HTMLElement | null) {
  const client: ApolloClient<InMemoryCache> = createClient()
  if (ENV.ASSIGNMENT_ID) {
    // eslint-disable-next-line no-restricted-properties
    ReactDOM.render(
      <ApolloProvider client={client}>
        <TeacherQuery assignmentLid={ENV.ASSIGNMENT_ID.toString()} />
      </ApolloProvider>,
      elt
    )
  }
}
