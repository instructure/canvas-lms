/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import {RouterProvider} from 'react-router-dom'
import {QueryClientProvider} from '@tanstack/react-query'
import {router} from './routes/router'
import {AccessibilityErrorBoundary} from './react/components/AccessibilityErrorBoundary'
import {queryClient} from '@canvas/query'

render(
  <React.StrictMode>
    <AccessibilityErrorBoundary>
      <QueryClientProvider client={queryClient}>
        <RouterProvider router={router} />
      </QueryClientProvider>
    </AccessibilityErrorBoundary>
  </React.StrictMode>,
  document.getElementById('content'),
)
