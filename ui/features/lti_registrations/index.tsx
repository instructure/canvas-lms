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
import * as React from 'react'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {createRoot} from 'react-dom/client'
import {createBrowserRouter, RouterProvider} from 'react-router-dom'
import ProductDetail from '../../shared/lti-apps/components/ProductDetail/ProductDetail'
import {DiscoverRoute} from './discover'
import {LtiAppsLayout} from './layout/LtiAppsLayout'
import {ManageRoutes} from './manage'
import {
  deleteDeveloperKey,
  updateAdminNickname,
  updateDeveloperKeyWorkflowState,
} from './manage/api/developerKey'
import {
  fetchRegistrationToken,
  getLtiImsRegistrationById,
  getRegistrationByUUID,
  updateRegistrationOverlay,
} from './manage/api/ltiImsRegistration'
import {
  bindGlobalLtiRegistration,
  createRegistration,
  fetchRegistrationByClientId,
  fetchThirdPartyToolConfiguration,
  updateRegistration,
  fetchLtiRegistration,
} from './manage/api/registrations'
import type {DynamicRegistrationWizardService} from './manage/dynamic_registration_wizard/DynamicRegistrationWizardService'
import {InheritedKeyRegistrationWizard} from './manage/inherited_key_registration_wizard/InheritedKeyRegistrationWizard'
import type {InheritedKeyService} from './manage/inherited_key_registration_wizard/InheritedKeyService'
import type {Lti1p3RegistrationWizardService} from './manage/lti_1p3_registration_form/Lti1p3RegistrationWizardService'
import {openDynamicRegistrationWizard} from './manage/registration_wizard/RegistrationWizardModalState'
import {getBasename} from '@canvas/lti-apps/utils/basename'
import {ZAccountId} from './manage/model/AccountId'
import type {JsonUrlWizardService} from './manage/registration_wizard/JsonUrlWizardService'
import {RegistrationWizardModal} from './manage/registration_wizard/RegistrationWizardModal'
import {ProductConfigureButton} from './discover/ProductConfigureButton'

const accountId = ZAccountId.parse(window.location.pathname.split('/')[2])

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
      element: (
        <ProductDetail
          renderConfigureButton={(buttonWidth, ltiConfiguration) => {
            return (
              <ProductConfigureButton
                accountId={accountId}
                buttonWidth={buttonWidth}
                ltiConfiguration={ltiConfiguration}
              />
            )
          }}
        />
      ),
    },
  ],

  {
    basename: getBasename('apps'),
  }
)

const dynamicRegistrationWizardService: DynamicRegistrationWizardService = {
  deleteDeveloperKey,
  fetchRegistrationToken,
  getRegistrationByUUID,
  getLtiImsRegistrationById,
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
  fetchLtiRegistration,
}

const inheritedKeyService: InheritedKeyService = {
  bindGlobalLtiRegistration,
  fetchRegistrationByClientId,
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
    <InheritedKeyRegistrationWizard accountId={accountId} service={inheritedKeyService} />
    <RouterProvider router={router} />
  </QueryClientProvider>
)
