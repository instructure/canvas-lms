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
import {createRoot} from 'react-dom/client'
import {createBrowserRouter, RouterProvider} from 'react-router-dom'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {LtiAppsLayout} from './layout/LtiAppsLayout'
import {DiscoverRoute} from './discover/components'
import {ManageRoutes} from './manage'
import ProductDetail from './discover/components/ProductDetail/ProductDetail'
import {ZAccountId} from './manage/model/AccountId'
import {RegistrationWizardModal} from './manage/registration_wizard/RegistrationWizardModal'
import type {DynamicRegistrationWizardService} from './manage/dynamic_registration_wizard/DynamicRegistrationWizardService'
import {
  fetchRegistrationToken,
  getRegistrationById,
  getRegistrationByUUID,
  updateRegistrationOverlay,
} from './manage/api/ltiImsRegistration'
import {
  deleteDeveloperKey,
  updateAdminNickname,
  updateDeveloperKeyWorkflowState,
} from './manage/api/developerKey'
import {
  fetchThirdPartyToolConfiguration,
  createRegistration,
  updateRegistration,
} from './manage/api/registrations'
import type {JsonUrlWizardService} from './manage/registration_wizard/JsonUrlWizardService'
import type {Lti1p3RegistrationWizardService} from './manage/lti_1p3_registration_form/Lti1p3RegistrationWizardService'

const getBasename = () => {
  const path = window.location.pathname
  const parts = path.split('/')
  return parts.slice(0, parts.indexOf('apps') + 1).join('/')
}

const queryClient = new QueryClient()

// window.ENV.lti_registrations_discover_page

const router = createBrowserRouter(
  [
    {
      path: '/',
      element: <LtiAppsLayout />,
      children: window.ENV.FEATURES.lti_registrations_discover_page
        ? [DiscoverRoute, ...ManageRoutes]
        : [...ManageRoutes],
    },
    {
      path: 'product_detail/:id',
      element: <ProductDetail />,
    },
  ],

  {
    basename: getBasename(),
  }
)

const accountId = ZAccountId.parse(window.location.pathname.split('/')[2])

const dynamicRegistrationWizardService: DynamicRegistrationWizardService = {
  deleteDeveloperKey,
  fetchRegistrationToken,
  getRegistrationByUUID,
  getRegistrationById,
  updateDeveloperKeyWorkflowState,
  updateAdminNickname,
  updateRegistrationOverlay,
}

const jsonUrlWizardService: JsonUrlWizardService = {
  fetchThirdPartyToolConfiguration,
}

const lti1p3RegistrationWizardService: Lti1p3RegistrationWizardService = {
  createLtiRegistration: createRegistration,
  updateLtiRegistration: updateRegistration,
}

const root = createRoot(document.getElementById('reactContent')!)

root.render(
  <QueryClientProvider client={queryClient}>
    <RegistrationWizardModal
      accountId={accountId}
      dynamicRegistrationWizardService={dynamicRegistrationWizardService}
      lti1p3RegistrationWizardService={lti1p3RegistrationWizardService}
      jsonUrlWizardService={jsonUrlWizardService}
    />
    <RouterProvider router={router} />
  </QueryClientProvider>
)
