/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {createRoot} from 'react-dom/client'
import JobsIndex from './react'
import ready from '@instructure/ready'
import {ApolloProvider, createClient} from '@canvas/apollo-v3'

ready(() => {
  const container = document.getElementById('content')
  if (!container) {
    throw new Error('Failed to find root container element')
  }

  const root = createRoot(container)
  root.render(
    <ApolloProvider client={createClient()}>
      <JobsIndex />
    </ApolloProvider>,
  )
})
