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
import ProductDetail from '@canvas/lti-apps/components/ProductDetail/ProductDetail'
import {getBasename} from '@canvas/lti-apps/utils/basename'
import {QueryClientProvider} from '@tanstack/react-query'
import {render} from '@canvas/react'
import {Navigate, RouterProvider, createBrowserRouter} from 'react-router-dom'
import {DiscoverRoute} from './discover'
import {ProductConfigureButton} from './discover/ProductConfigureButton'
import {isLtiRegistrationsDiscoverEnabled} from './discover/utils'
import {LtiAppsLayout} from './layout/LtiAppsLayout'
import {ManageRoutes} from './manage'
import {
  applyLtiRegistrationUpdateRequest,
  fetchRegistrationToken,
  getLtiRegistrationByUUID,
  getLtiRegistrationUpdateRequestByUUID,
} from './manage/api/ltiImsRegistration'
import {
  bindGlobalLtiRegistration,
  createRegistration,
  deleteRegistration,
  fetchLtiRegistration,
  fetchRegistrationByClientId,
  fetchThirdPartyToolConfiguration,
  updateRegistration,
} from './manage/api/registrations'
import type {DynamicRegistrationWizardService} from './manage/dynamic_registration_wizard/DynamicRegistrationWizardService'
import {InheritedKeyRegistrationWizard} from './manage/inherited_key_registration_wizard/InheritedKeyRegistrationWizard'
import type {InheritedKeyService} from './manage/inherited_key_registration_wizard/InheritedKeyService'
import type {Lti1p3RegistrationWizardService} from './manage/lti_1p3_registration_form/Lti1p3RegistrationWizardService'
import {type AccountId} from './manage/model/AccountId'
import {ToolDetails} from './manage/pages/tool_details/ToolDetails'
import {ToolAvailability} from './manage/pages/tool_details/availability/ToolAvailability'
import {ToolConfigurationView} from './manage/pages/tool_details/configuration/ToolConfigurationView'
import {ToolHistory} from './manage/pages/tool_details/history/ToolHistory'
import {ToolUsage} from './manage/pages/tool_details/usage/ToolUsage'
import type {JsonUrlWizardService} from './manage/registration_wizard/JsonUrlWizardService'
import {RegistrationWizardModal} from './manage/registration_wizard/RegistrationWizardModal'
import {route as MonitorRoute} from './monitor/route'
import {isLtiRegistrationsUsageEnabled} from './monitor/utils'
import {ToolConfigurationEdit} from './manage/pages/tool_details/configuration/ToolConfigurationEdit'
import {
  deleteContextControl,
  fetchControlsByDeployment,
  updateContextControl,
} from './manage/api/contextControls'
import {deleteDeployment} from './manage/api/deployments'
import {queryClient} from '@canvas/query'
import {getAccountId} from './common/lib/getAccountId'
import {LtiBreadcrumbsLayout} from './layout/LtiBreadcrumbsLayout'
import {RegistrationUpdateWizardModal} from './manage/registration_update_wizard/RegistrationUpdateWizardModal'

const accountId = getAccountId()

const getLayoutChildren = (accountId: AccountId) => {
  const layoutRoutes = [...ManageRoutes]

  if (isLtiRegistrationsDiscoverEnabled()) {
    layoutRoutes.push(DiscoverRoute)
  }

  if (isLtiRegistrationsUsageEnabled()) {
    layoutRoutes.push(MonitorRoute(accountId))
  }

  return layoutRoutes
}

const router = createBrowserRouter(
  [
    {
      path: '',
      element: <LtiBreadcrumbsLayout accountId={accountId} />,
      // If you add a new route, you almost certainly need to add it here to ensure that the
      // correct top level breadcrumb is always added. If you don't, it will be up to you
      // to ensure that the top level breadcrumb is added correctly.
      children: [
        {
          path: '/',
          element: <LtiAppsLayout />,
          children: getLayoutChildren(accountId),
        },
        {
          path: 'product_detail/:id',
          element: (
            <ProductDetail
              renderConfigureButton={(buttonWidth, product) => {
                return (
                  <ProductConfigureButton
                    accountId={accountId}
                    buttonWidth={buttonWidth}
                    product={product}
                  />
                )
              }}
            />
          ),
        },
        {
          path: 'manage/:registration_id',
          element: <ToolDetails accountId={accountId} />,
          children: [
            {
              path: '',
              element: (
                <ToolAvailability
                  fetchControlsByDeployment={fetchControlsByDeployment}
                  editContextControl={updateContextControl}
                  accountId={accountId}
                  deleteContextControl={deleteContextControl}
                  deleteDeployment={deleteDeployment}
                />
              ),
            },
            {
              path: 'configuration',
              element: <ToolConfigurationView />,
            },
            {
              path: 'configuration/edit',
              element: <ToolConfigurationEdit />,
            },
            ...(isLtiRegistrationsUsageEnabled()
              ? [
                  {
                    path: 'usage',
                    element: <ToolUsage />,
                  },
                ]
              : []),
            {
              path: 'history',
              element: <ToolHistory accountId={accountId} />,
            },
          ],
        },
        {
          path: '*',
          element: <Navigate to="/" replace />,
        },
      ],
    },
  ],

  {
    basename: getBasename('apps'),
  },
)

const dynamicRegistrationWizardService: DynamicRegistrationWizardService = {
  fetchRegistrationToken,
  getRegistrationByUUID: getLtiRegistrationByUUID,
  getLtiRegistrationUpdateRequestByUUID,
  fetchLtiRegistration,
  updateRegistration,
  applyLtiRegistrationUpdateRequest,
  deleteRegistration,
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

render(
  <QueryClientProvider client={queryClient}>
    <RegistrationWizardModal
      accountId={accountId}
      dynamicRegistrationWizardService={dynamicRegistrationWizardService}
      lti1p3RegistrationWizardService={lti1p3RegistrationWizardService}
      jsonUrlWizardService={jsonUrlWizardService}
    />
    <RegistrationUpdateWizardModal accountId={accountId} />
    <InheritedKeyRegistrationWizard accountId={accountId} service={inheritedKeyService} />
    <RouterProvider router={router} />
  </QueryClientProvider>,
  document.getElementById('reactContent'),
)
