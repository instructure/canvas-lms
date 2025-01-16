/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import ReactDOM from 'react-dom/client'
import React from 'react'
import {
  createBrowserRouter,
  createRoutesFromElements,
  Route,
  RouterProvider,
} from 'react-router-dom'
import {Spinner} from '@instructure/ui-spinner'
import accountGradingSettingsRoutes from '../../features/account_grading_settings/routes/accountGradingSettingsRoutes'
import {RubricRoutes} from '../../features/rubrics/routes/rubricRoutes'
import {NewLoginRoutes} from '../../features/new_login/routes/NewLoginRoutes'
import {useScope as createI18nScope} from '@canvas/i18n'
import {QueryProvider} from '@canvas/query'
import {AUPRoutes} from '../../features/acceptable_use_policy/routes/AUPRoutes'

const portalRouter = createBrowserRouter(
  createRoutesFromElements(
    <Route>
      <Route
        path="/groups/:groupId/*"
        lazy={() => import('@canvas/group-navigation-selector/GroupNavigationSelectorRoute')}
      />
      <Route
        path="/users/:userId/masquerade"
        lazy={() => import('../../features/act_as_modal/react/ActAsModalRoute')}
      />
      <Route
        path="/accounts/:accountId/users/:userId"
        lazy={() => import('../../features/page_views/react/PageViewsRoute')}
      />
      <Route
        path="/accounts"
        lazy={() => import('../../features/account_manage/react/AccountListRoute')}
      />
      <Route
        path="/users/:userId"
        lazy={() => import('../../features/page_views/react/PageViewsRoute')}
      />

      {accountGradingSettingsRoutes}

      {(window.ENV.FEATURES.instui_nav || localStorage.instui_nav_dev) &&
        ['/', '/*', '/*/*'].map(path => (
          <Route
            key={`key-to-${path}`}
            path={path}
            lazy={() => import('../../features/navigation_header/react/NavigationHeaderRoute')}
          />
        ))}

      {window.ENV.FEATURES.login_registration_ui_identity && NewLoginRoutes}

      {AUPRoutes}

      {window.ENV.enhanced_rubrics_enabled && RubricRoutes}

      <Route path="*" element={<></>} />
    </Route>
  )
)

export function loadReactRouter() {
  const mountNode = document.querySelector('#react-router-portals')

  const I18n = createI18nScope('main')
  if (mountNode) {
    const root = ReactDOM.createRoot(mountNode)
    root.render(
      <QueryProvider>
        <RouterProvider
          router={portalRouter}
          fallbackElement={<Spinner renderTitle={I18n.t('Loading page')} />}
        />
      </QueryProvider>
    )
  }
}
