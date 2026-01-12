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
import {render} from '@canvas/react'
import {ApolloClient, ApolloProvider} from '@apollo/client'
import TeacherQuery from './TeacherQuery'
import {createClient} from '@canvas/apollo-v3'
import type {InMemoryCache} from '@apollo/client'
import AlertManager from '@canvas/alerts/react/AlertManager'

export default function renderAssignmentsApp(elt: HTMLElement | null) {
  const client: ApolloClient<InMemoryCache> = createClient()
  if (ENV.ASSIGNMENT_ID && elt) {
    render(
      <ApolloProvider client={client}>
        {/* @ts-expect-error */}
        <AlertManager>
          <TeacherQuery assignmentLid={ENV.ASSIGNMENT_ID.toString()} />
        </AlertManager>
      </ApolloProvider>,
      elt,
    )
  }
}
