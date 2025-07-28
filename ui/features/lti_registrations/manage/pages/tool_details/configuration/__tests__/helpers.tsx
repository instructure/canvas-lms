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
import {render} from '@testing-library/react'
import React from 'react'
import {
  createMemoryRouter,
  MemoryRouter,
  Outlet,
  Route,
  RouterProvider,
  Routes,
} from 'react-router-dom'
import {InternalLtiConfiguration} from '../../../../model/internal_lti_configuration/InternalLtiConfiguration'
import {LtiRegistrationWithAllInformation} from '../../../../model/LtiRegistration'
import {
  mockRegistration,
  mockRegistrationWithAllInformation,
} from '../../../manage/__tests__/helpers'
import {LtiOverlay, LtiOverlayWithVersions} from '../../../../model/LtiOverlay'
import {ZLtiOverlayId} from '../../../../model/ZLtiOverlayId'
import {ZAccountId} from '../../../../model/AccountId'
import {z} from 'zod'
import {ZUser} from '../../../../model/User'
import {ZUserId} from '../../../../model/UserId'
import {ZLtiRegistrationId} from '../../../../model/LtiRegistrationId'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'

export const mockConfiguration = (
  config: Partial<InternalLtiConfiguration>,
): InternalLtiConfiguration => {
  return {
    title: 'Test App',
    oidc_initiation_url: 'http://example.com',
    placements: [],
    scopes: [],
    target_link_uri: 'http://example.com',
    ...config,
  }
}

const mockUser = (user: Partial<z.TypeOf<typeof ZUser>>): z.TypeOf<typeof ZUser> => ({
  created_at: new Date(),
  id: ZUserId.parse('1'),
  name: 'Test User',
  short_name: 'TU',
  sortable_name: 'User, Test',
  ...user,
})

export const mockOverlay = (
  overlay: Partial<LtiOverlay>,
  user: Partial<z.TypeOf<typeof ZUser>>,
): LtiOverlayWithVersions => {
  return {
    id: ZLtiOverlayId.parse('1'),
    account_id: ZAccountId.parse('1'),
    created_at: new Date(),
    updated_at: new Date(),
    updated_by: mockUser(user),
    registration_id: ZLtiRegistrationId.parse('1'),
    root_account_id: ZAccountId.parse('1'),
    data: {},
    versions: [],
    ...overlay,
  }
}

export const renderAppWithRegistration =
  (registration: LtiRegistrationWithAllInformation, refreshRegistration: () => void = jest.fn()) =>
  (element: React.ReactNode) => {
    const queryClient = new QueryClient()
    const router = createMemoryRouter([
      {
        path: '*',
        element: (
          <Routes>
            <Route
              path="/"
              element={
                <Outlet
                  context={{
                    registration,
                    refreshRegistration,
                  }}
                />
              }
            >
              <Route index element={element} />
            </Route>
          </Routes>
        ),
      },
    ])
    return render(
      <QueryClientProvider client={queryClient}>
        <RouterProvider router={router} />
      </QueryClientProvider>,
    )
  }

export const renderApp = (...p: Parameters<typeof mockRegistrationWithAllInformation>) =>
  renderAppWithRegistration(mockRegistrationWithAllInformation(...p))
