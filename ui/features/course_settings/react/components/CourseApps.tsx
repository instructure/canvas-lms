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
import {createBrowserRouter, RouterProvider} from 'react-router-dom'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {InstructorApps} from '../../../../shared/lti-apps/components/InstructorApps'
import ProductDetail from '../../../../shared/lti-apps/components/ProductDetail/ProductDetail'
import {getBasename} from '@canvas/lti-apps/utils/basename'
import {instructorAppsRoute} from '@canvas/lti-apps/utils/routes'

export const CourseApps = () => {
  const router = createBrowserRouter(
    [
      {
        id: 'root',
        path: '/',
        element: <InstructorApps />,
      },
      {
        id: 'product_detail',
        path: 'product_detail/:id',
        element: <ProductDetail />,
      },
    ],
    {basename: getBasename(instructorAppsRoute)},
  )
  const queryClient = new QueryClient()

  return (
    <QueryClientProvider client={queryClient}>
      <RouterProvider router={router} />
    </QueryClientProvider>
  )
}

export default CourseApps
