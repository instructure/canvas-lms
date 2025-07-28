/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {MemoryRouter, Outlet, Route, Routes} from 'react-router-dom'
import type {LtiRegistrationWithAllInformation} from '../../../model/LtiRegistration'
import {mockRegistrationWithAllInformation} from '../../manage/__tests__/helpers'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'

export type RenderArgs = {
  registration?: LtiRegistrationWithAllInformation
  child: React.ReactNode
}

export const renderWithRouter = ({
  registration = mockRegistrationWithAllInformation({n: 'foo', i: 1}),
  child,
}: RenderArgs) => {
  const queryClient = new QueryClient()
  return (
    <QueryClientProvider client={queryClient}>
      <MemoryRouter>
        <Routes>
          <Route
            path="/"
            element={
              <Outlet
                context={{
                  registration,
                }}
              />
            }
          >
            <Route index element={child} />
          </Route>
        </Routes>
      </MemoryRouter>
    </QueryClientProvider>
  )
}
